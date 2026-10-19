// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "ReusableRoutingKit",
  platforms: [.iOS(.v15)],
  products: [
    .library(name: "ReusableRoutingKit", targets: ["ReusableRoutingKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/markbattistella/BrowserKit.git", branch: "main")
  ],
  targets: [
    .target(
      name: "ReusableRoutingKit",
      dependencies: [
        .product(name: "BrowserKit", package: "BrowserKit")
      ]
    )
  ],
  swiftLanguageModes: [.v5]
)
