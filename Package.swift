// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Prompty",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Prompty", targets: ["Prompty"])
    ],
    targets: [
        .executableTarget(
            name: "Prompty",
            path: "Sources/PromptBarApp",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
