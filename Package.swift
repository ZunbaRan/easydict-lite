// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Easydict",
    defaultLocalization: "en",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "easydict-lite", targets: ["Easydict"])],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.12.2"),
        .package(url: "https://github.com/sindresorhus/Defaults.git", exact: "8.2.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", exact: "5.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "Easydict",
            dependencies: ["Alamofire", "Defaults", "SFSafeSymbols"],
            path: "Easydict/Swift/Focused",
            resources: [.process("Resources")],
            linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("Security")]
        ),
        .testTarget(
            name: "EasydictTests",
            dependencies: ["Easydict"],
            path: "EasydictTests",
            sources: [
                "Support/TestSuites.swift",
                "Utility/ThrottleGateTests.swift",
                "Service/OpenAI/OpenAIStreamTaskControlTests.swift",
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
