// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TI84Calculator",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TI84App", targets: ["TI84App"]),
    ],
    dependencies: [
        .package(path: "Packages/TI84Core"),
        .package(path: "Packages/TI84Engine"),
    ],
    targets: [
        .executableTarget(
            name: "TI84App",
            dependencies: ["TI84Core", "TI84Engine"],
            path: "TI84App/TI84App"
        ),
    ]
)
