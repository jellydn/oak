// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Oak",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Oak", targets: ["Oak"])
    ],
    targets: [
        .executableTarget(
            name: "Oak",
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        )
    ]
)
