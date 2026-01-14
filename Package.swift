// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIMacTools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacToolsCore",
            targets: ["MacToolsCore"]
        ),
        .executable(
            name: "AIMacTools",
            targets: ["AIMacTools"]
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
            name: "AIMacTools",
            dependencies: ["MacToolsCore"]
        ),
        .testTarget(
            name: "MacToolsCoreTests",
            dependencies: ["MacToolsCore"]
        )
    ]
)
