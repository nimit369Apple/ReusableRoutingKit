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
        .package(
                url: "https://github.com/markbattistella/BrowserKit.git",
                from: "26.0.0"
            )
    ],
    targets: [
        .binaryTarget(
            name: "ReusableRoutingKit",
            url: "https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.1/ReusableRoutingKit-1.0.1.xcframework.zip",
            checksum: "55d6a33cdc3cc1a20851cda2f7628910290358f22adabffb11be623a0c8a2e79"
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
