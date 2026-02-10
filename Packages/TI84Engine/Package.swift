// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TI84Engine",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TI84Engine", targets: ["TI84Engine"]),
    ],
    dependencies: [
        .package(path: "../TI84Core"),
    ],
    targets: [
        .target(
            name: "TI84Engine",
            dependencies: ["TI84Core"],
            path: "Sources"
        ),
        .testTarget(
            name: "TI84EngineTests",
            dependencies: ["TI84Engine"],
            path: "Tests/TI84EngineTests"
        ),
    ]
)
