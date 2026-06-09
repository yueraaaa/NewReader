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
        .package(url: "https://github.com/nmdias/FeedKit", from: "9.1.2"),
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "NewReaderCore",
            dependencies: ["FeedKit", .product(name: "Supabase", package: "supabase-swift")],
            path: "Sources/NewReaderCore"
        ),
        .testTarget(
            name: "NewReaderCoreTests",
            dependencies: ["NewReaderCore"],
            path: "Tests/NewReaderCoreTests"
        ),
        .executableTarget(
            name: "NewReaderMac",
            dependencies: ["NewReaderCore"],
            path: "Sources/NewReaderMac",
            exclude: ["Info.plist", "NewReader.entitlements", "Secrets.plist", "Secrets.plist.template"],
            resources: [
                .process("AppIcon.icns")
            ]
        ),
        .executableTarget(
            name: "NewReaderiOS",
            dependencies: ["NewReaderCore"],
            path: "Sources/NewReaderiOS",
            exclude: ["NewReader.entitlements"]
        )
    ]
)
