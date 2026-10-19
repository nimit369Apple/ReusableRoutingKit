// swift-tools-version: 6.0
import PackageDescription

// The BrowserKit and ReusableRoutingKit binaries are separate dynamic XCFrameworks.
// No upstream source BrowserKit package or static duplicate is added here.
let package = Package(
    name: "ReusableRoutingKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ReusableRoutingKit", targets: ["BrowserKit", "ReusableRoutingKit"])
    ],
    targets: [
        .binaryTarget(
            name: "BrowserKit",
            url: "https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.3/BrowserKit-1.0.3.xcframework.zip",
            checksum: "14ef546873a15fb33e4974e4e266c80595f92efd7d07bbc159c9c0e206464c69"
        ),
        .binaryTarget(
            name: "ReusableRoutingKit",
            url: "https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.3/ReusableRoutingKit-1.0.3.xcframework.zip",
            checksum: "111dbe4407290fe8b0d4417a15d0553895feb6abf986fc805190d60e16a80f06"
        )
    ]
)
