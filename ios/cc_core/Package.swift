// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "cc_core",
  platforms: [.iOS("13.0")],
  products: [.library(name: "cc-core", targets: ["cc_core"])],
  dependencies: [],
  targets: [.target(name: "cc_core", dependencies: [])]
)
