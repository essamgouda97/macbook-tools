// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacBookTools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacToolsCore",
            targets: ["MacToolsCore"]
        ),
        .executable(
            name: "FrancoTranslator",
            targets: ["FrancoTranslator"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.3.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .target(
            name: "MacToolsCore",
            dependencies: [
                .product(name: "OpenAI", package: "OpenAI"),
                .product(name: "KeychainAccess", package: "KeychainAccess")
            ]
        ),
        .executableTarget(
            name: "FrancoTranslator",
            dependencies: ["MacToolsCore"]
        ),
        .testTarget(
            name: "MacToolsCoreTests",
            dependencies: ["MacToolsCore"]
        ),
        .testTarget(
            name: "FrancoTranslatorTests",
            dependencies: ["FrancoTranslator", "MacToolsCore"]
        )
    ]
)
