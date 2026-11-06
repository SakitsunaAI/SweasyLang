// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "sweasy",
    products: [
        .executable(
            name: "sweasy",
            targets: ["sweasy"]
        ),
        .library(
            name: "SweasyCore",
            targets: ["SweasyCore"]
        )
    ],
    targets: [
        .target(
            name: "SweasyCore",
            dependencies: []
        ),
        .executableTarget(
            name: "sweasy",
            dependencies: ["SweasyCore"]
        ),
        .testTarget(
            name: "SweasyTests",
            dependencies: ["SweasyCore"]
        ),
    ]
)
