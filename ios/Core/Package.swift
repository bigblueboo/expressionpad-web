// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ExpressionPadCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ExpressionPadCore", targets: ["ExpressionPadCore"]),
    ],
    targets: [
        .target(
            name: "ExpressionPadCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ExpressionPadCoreTests",
            dependencies: ["ExpressionPadCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
