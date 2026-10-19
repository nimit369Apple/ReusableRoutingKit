// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReusableRoutingKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ReusableRoutingKit", targets: [
            "ReusableRoutingKit", "ReusableRoutingKitDependencies"
        ])
    ],
    // BrowserKit is a dependency of the current ReusableRoutingKit source.
    // A source target is used because binary targets cannot declare product dependencies.
    dependencies: [
        .package(url: "https://github.com/markbattistella/BrowserKit.git", branch: "main")
    ],
    targets: [
        .binaryTarget(
            name: "ReusableRoutingKit",
            url: "https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.0/ReusableRoutingKit-1.0.0.xcframework.zip",
            checksum: "767d977e510cf414b4b548252a4d88ce873d065549e332a1e124d5957ab290c4"
        ),
        .target(
            name: "ReusableRoutingKitDependencies",
            dependencies: [
                .product(name: "BrowserKit", package: "BrowserKit")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
