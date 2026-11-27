import 'package:flutter/services.dart';

/// How an envelope leaves the app. Android: cc_core's plugin
/// (android/.../CcCorePlugin.kt). Elsewhere (iOS until its App Group
/// pass, tests) calls answer null.
abstract class SuiteTransport {
  /// Quiet: files [text] in the first installed package's inbox. Returns
  /// that package, or null when none took it.
  Future<String?> deliver(String text, List<String> packages);

  /// Loud: opens the first package that accepts the suite MIME type with
  /// [text]. Returns that package, or null.
  Future<String?> share(String text, List<String> packages);

  /// The first of [packages] that's installed, or null.
  Future<String?> installed(List<String> packages);

  /// The back-link (`<scheme>://open/<id>`) the app was launched with,
  /// once; null after that or when there wasn't one.
  Future<String?> initialOpen();

  /// Back-links that arrive while the app is running. One that arrives
  /// before a handler is set waits for [initialOpen].
  void onOpen(void Function(String link) handler);

  /// The Kick Rocks envelope ("Log this in…") the app was handed, once;
  /// null after that or when there wasn't one.
  Future<String?> initialDraft();

  /// Drafts that arrive while the app is running. One that arrives
  /// before a handler is set waits for [initialDraft].
  void onDraft(void Function(String envelope) handler);
}

/// The real transport (cc_core's Android plugin).
class MethodChannelSuiteTransport implements SuiteTransport {
  /// Stateless.
  const MethodChannelSuiteTransport();

  static const _ch = MethodChannel('cc_core/suite_link');

  Future<String?> _call(String method, Map<String, Object?> args) async {
    try {
      return await _ch.invokeMethod<String>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> deliver(String text, List<String> packages) =>
      _call('deliver', {'text': text, 'packages': packages});

  @override
  Future<String?> share(String text, List<String> packages) =>
      _call('share', {'text': text, 'packages': packages});

  @override
  Future<String?> installed(List<String> packages) =>
      _call('installed', {'packages': packages});

  @override
  Future<String?> initialOpen() => _call('initialOpen', const {});

  @override
  Future<String?> initialDraft() => _call('initialDraft', const {});

  // One channel handler serves both nudges (setting a second would drop
  // the first), so the handlers are kept here.
  static void Function(String)? _onOpen;
  static void Function(String)? _onDraft;

  static void _listen() {
    // The plugin keeps the newest link/draft until it's read, so one that
    // arrived while no handler was listening isn't lost; "open" and
    // "draft" are just the nudges to read them.
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'open' && _onOpen != null) {
        final link = await const MethodChannelSuiteTransport().initialOpen();
        if (link != null) _onOpen?.call(link);
      } else if (call.method == 'draft' && _onDraft != null) {
        final d = await const MethodChannelSuiteTransport().initialDraft();
        if (d != null) _onDraft?.call(d);
      }
    });
  }

  @override
  void onOpen(void Function(String link) handler) {
    _onOpen = handler;
    _listen();
  }

  @override
  void onDraft(void Function(String envelope) handler) {
    _onDraft = handler;
    _listen();
  }
}

/// Records what was sent; [installedPackage] decides who's "on the phone".
class FakeSuiteTransport implements SuiteTransport {
  /// A phone with [installedPackage] (or nothing) installed.
  FakeSuiteTransport({this.installedPackage});

  /// The one package that's "installed".
  String? installedPackage;

  /// Envelopes [deliver] accepted.
  final delivered = <String>[];

  /// Envelopes [share] accepted.
  final shared = <String>[];

  /// Every [deliver] call, taken or not: proves a feed was attempted.
  final deliverAttempts = <String>[];

  /// Every [share] call, taken or not.
  final shareAttempts = <String>[];

  String? _first(List<String> packages) =>
      packages.contains(installedPackage) ? installedPackage : null;

  @override
  Future<String?> deliver(String text, List<String> packages) async {
    deliverAttempts.add(text);
    final p = _first(packages);
    if (p != null) delivered.add(text);
    return p;
  }

  @override
  Future<String?> share(String text, List<String> packages) async {
    shareAttempts.add(text);
    final p = _first(packages);
    if (p != null) shared.add(text);
    return p;
  }

  @override
  Future<String?> installed(List<String> packages) async => _first(packages);

  /// What [initialOpen] answers (once).
  String? launchLink;

  /// The handler [onOpen] registered; call it to simulate a link.
  void Function(String link)? openHandler;

  @override
  Future<String?> initialOpen() async {
    final l = launchLink;
    launchLink = null;
    return l;
  }

  @override
  void onOpen(void Function(String link) handler) => openHandler = handler;

  /// What [initialDraft] answers (once).
  String? launchDraft;

  /// The handler [onDraft] registered; call it to simulate a draft.
  void Function(String envelope)? draftHandler;

  @override
  Future<String?> initialDraft() async {
    final d = launchDraft;
    launchDraft = null;
    return d;
  }

  @override
  void onDraft(void Function(String envelope) handler) => draftHandler = handler;
}
