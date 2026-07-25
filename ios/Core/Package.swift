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
            swiftSettings: [
                .swiftLanguageMode(.v5),
                // The source-node callback has a hard real-time deadline.
                // Swift's unoptimized Array/bounds/exclusivity checks make the
                // wavetable + FX kernel several times slower than real time,
                // even though the surrounding app should remain debuggable.
                .unsafeFlags(["-O"], .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "ExpressionPadCoreTests",
            dependencies: ["ExpressionPadCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
