// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NewReader",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "NewReaderCore", targets: ["NewReaderCore"]),
        .executable(name: "NewReaderMac", targets: ["NewReaderMac"]),
        .executable(name: "NewReaderiOS", targets: ["NewReaderiOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit", from: "9.1.2")
    ],
    targets: [
        .target(
            name: "NewReaderCore",
            dependencies: ["FeedKit"],
            path: "Sources/NewReaderCore"
        ),
        .executableTarget(
            name: "NewReaderMac",
            dependencies: ["NewReaderCore"],
            path: "Sources/NewReaderMac"
        ),
        .executableTarget(
            name: "NewReaderiOS",
            dependencies: ["NewReaderCore"],
            path: "Sources/NewReaderiOS"
        )
    ]
)
