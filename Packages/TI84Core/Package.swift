// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TI84Core",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TI84Core", targets: ["TI84Core"]),
    ],
    targets: [
        .target(name: "TI84Core"),
        .testTarget(name: "TI84CoreTests", dependencies: ["TI84Core"]),
    ]
)
