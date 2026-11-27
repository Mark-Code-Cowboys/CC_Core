import Flutter
import UIKit

/// cc_core's iOS half: Suite Link (lib/src/suite_link), the same
/// `cc_core/suite_link` channel and methods as the Android plugin, so the
/// apps' Dart code is unchanged.
///
/// - `deliver` (quiet feed): writes the envelope into the shared App Group
///   container, `suite_inbox/q__<bundle id>__<ms>-<rand>.json`. Only apps
///   of the Code Cowboys team can join the group, so the file name's sender
///   can be trusted. Kick Rocks drains the folder when it next opens.
/// - `share` ("Send to Kick Rocks"): opens `kickrocks://suite/moment?e=<envelope>`.
/// - `installed`: Kick Rocks' scheme answers `canOpenURL` (the app lists it
///   under LSApplicationQueriesSchemes).
/// - Back-links (`<scheme>://open/<id>`) and drafts from Kick Rocks' "Log
///   this in…" (`<scheme>://suite/draft?e=<envelope>`) are kept until Dart
///   reads them (`initialOpen` / `initialDraft`); `open` / `draft` nudge a
///   running app. A draft whose sender iOS names (same team only) must be
///   Kick Rocks; it only pre-fills a form the user still has to save.
public class CcCorePlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  static let appGroup = "group.com.codecowboys.suite"
  static let kickRocks = "com.codecowboys.kickrocks"
  static let maxBytes = 65536

  private let channel: FlutterMethodChannel
  private var pendingOpen: String?
  private var pendingDraft: String?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cc_core/suite_link", binaryMessenger: registrar.messenger())
    let instance = CcCorePlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let packages = args["packages"] as? [String] ?? []
    switch call.method {
    case "installed":
      result(firstInstalled(packages))
    case "deliver":
      let text = args["text"] as? String ?? ""
      DispatchQueue.global(qos: .utility).async {
        let took = self.deliver(text, packages)
        DispatchQueue.main.async { result(took) }
      }
    case "share":
      share(args["text"] as? String ?? "", packages, result)
    case "initialOpen":
      result(pendingOpen)
      pendingOpen = nil
    case "initialDraft":
      result(pendingDraft)
      pendingDraft = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Incoming URLs

  public func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                    options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
    guard let contexts = connectionOptions?.urlContexts, !contexts.isEmpty else { return false }
    return take(contexts, nudge: false)
  }

  public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    take(URLContexts, nudge: true)
  }

  /// Pre-scene fallback (an app without a scene manifest).
  public func application(_ app: UIApplication, open url: URL,
                          options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    take(url, from: options[.sourceApplication] as? String, nudge: true)
  }

  private func take(_ contexts: Set<UIOpenURLContext>, nudge: Bool) -> Bool {
    var handled = false
    for c in contexts where take(c.url, from: c.options.sourceApplication, nudge: nudge) {
      handled = true
    }
    return handled
  }

  /// One of ours? `open/<id>` back-link or `suite/draft?e=`. Anything else
  /// (Kick Rocks' own `suite/moment`, other plugins' URLs) is left alone.
  private func take(_ url: URL, from sender: String?, nudge: Bool) -> Bool {
    guard let mine = Self.ownSchemes(), let scheme = url.scheme?.lowercased(), mine.contains(scheme) else {
      return false
    }
    if url.host == "open" {
      pendingOpen = url.absoluteString
      if nudge { channel.invokeMethod("open", arguments: nil) }
      return true
    }
    if url.host == "suite", url.path == "/draft" {
      // iOS names the sender only for apps of the same team; a named
      // sender that isn't Kick Rocks is refused.
      if let s = sender, s != Self.kickRocks, s != Self.kickRocks + ".dev" { return true }
      guard let text = Self.envelope(in: url) else { return true }
      pendingDraft = text
      if nudge { channel.invokeMethod("draft", arguments: nil) }
      return true
    }
    return false
  }

  // MARK: - Outgoing

  private func firstInstalled(_ packages: [String]) -> String? {
    packages.first { pkg in
      guard let url = Self.schemeURL(pkg) else { return false }
      return UIApplication.shared.canOpenURL(url)
    }
  }

  private func deliver(_ text: String, _ packages: [String]) -> String? {
    guard text.utf8.count <= Self.maxBytes,
          let target = DispatchQueue.main.sync(execute: { firstInstalled(packages) }),
          let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup)
    else { return nil }
    let dir = root.appendingPathComponent("suite_inbox", isDirectory: true)
    let me = Bundle.main.bundleIdentifier ?? "unknown"
    let ms = Int(Date().timeIntervalSince1970 * 1000)
    let name = "q__\(me)__\(ms)-\(Int.random(in: 0..<1_000_000)).json"
    do {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      // Written whole, then renamed: Kick Rocks never sees half a file.
      let tmp = dir.appendingPathComponent(".\(name).tmp")
      try Data(text.utf8).write(to: tmp, options: .atomic)
      try FileManager.default.moveItem(at: tmp, to: dir.appendingPathComponent(name))
      return target
    } catch {
      NSLog("SuiteLink deliver: \(error)")
      return nil
    }
  }

  private func share(_ text: String, _ packages: [String], _ result: @escaping FlutterResult) {
    guard text.utf8.count <= Self.maxBytes, let target = firstInstalled(packages),
          let scheme = Self.scheme(target),
          let url = Self.envelopeURL(scheme: scheme, path: "/moment", text: text)
    else { return result(nil) }
    UIApplication.shared.open(url, options: [:]) { ok in result(ok ? target : nil) }
  }

  // MARK: - Helpers

  /// `com.codecowboys.kickrocks` (or `.dev`) → `kickrocks`.
  static func scheme(_ package: String) -> String? {
    let prefix = "com.codecowboys."
    guard package.hasPrefix(prefix) else { return nil }
    return package.dropFirst(prefix.count).split(separator: ".").first.map(String.init)
  }

  static func schemeURL(_ package: String) -> URL? {
    scheme(package).flatMap { URL(string: "\($0)://") }
  }

  /// `<scheme>://suite<path>?e=<base64url envelope>`.
  static func envelopeURL(scheme: String, path: String, text: String) -> URL? {
    var c = URLComponents()
    c.scheme = scheme
    c.host = "suite"
    c.path = path
    c.queryItems = [URLQueryItem(name: "e", value: base64url(Data(text.utf8)))]
    return c.url
  }

  static func envelope(in url: URL) -> String? {
    guard let e = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "e" })?.value,
      let data = unbase64url(e), data.count <= maxBytes else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func base64url(_ d: Data) -> String {
    d.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  static func unbase64url(_ s: String) -> Data? {
    var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while b.count % 4 != 0 { b += "=" }
    return Data(base64Encoded: b)
  }

  /// The URL schemes this app registers (CFBundleURLTypes).
  static func ownSchemes() -> Set<String>? {
    guard let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
      return nil
    }
    let all = types.flatMap { ($0["CFBundleURLSchemes"] as? [String]) ?? [] }.map { $0.lowercased() }
    return all.isEmpty ? nil : Set(all)
  }
}
