// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DemoCLI",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "demo", targets: ["DemoCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "DemoCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
