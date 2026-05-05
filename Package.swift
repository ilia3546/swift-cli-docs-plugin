// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-cli-docs-plugin",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .plugin(
            name: "SwiftCLIDocsPlugin",
            targets: ["SwiftCLIDocsPlugin"]
        ),
        .executable(
            name: "swift-cli-docs",
            targets: ["swift-cli-docs"]
        ),
        .library(
            name: "CLIDocsCore",
            targets: ["CLIDocsCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.1.0"),
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.15.1"),
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.1"),
    ],
    targets: [
        .plugin(
            name: "SwiftCLIDocsPlugin",
            capability: .command(
                intent: .custom(
                    verb: "generate-docs",
                    description: "Generate Markdown documentation for Swift Argument Parser CLI tools."
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "Writes generated Markdown documentation to the configured output directory."),
                ]
            ),
            dependencies: [
                .target(name: "swift-cli-docs"),
            ],
            path: "Plugins/SwiftCLIDocsPlugin"
        ),
        .executableTarget(
            name: "swift-cli-docs",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .target(name: "CLIDocsCore"),
            ],
            path: "Sources/swift-cli-docs"
        ),
        .target(
            name: "CLIDocsCore",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "PathKit", package: "PathKit"),
            ],
            path: "Sources/CLIDocsCore",
            resources: [
                .copy("Resources/Themes"),
            ]
        ),
        .testTarget(
            name: "CLIDocsCoreTests",
            dependencies: ["CLIDocsCore"],
            path: "Tests/CLIDocsCoreTests",
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)
