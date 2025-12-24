// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "NKWalk",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "NKWalk",
            targets: ["NKWalk"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "NKWalk",
            dependencies: [
                "NKWalkCore",
                "NKWalkUI"
            ],
            path: "Sources/NKWalk"
        ),
        .target(
            name: "NKWalkCore",
            dependencies: [],
            path: "Sources/NKWalkCore"
        ),
        .target(
            name: "NKWalkUI",
            dependencies: ["NKWalkCore"],
            path: "Sources/NKWalkUI"
        ),
        .testTarget(
            name: "NKWalkTests",
            dependencies: ["NKWalk"],
            path: "Tests/NKWalkTests"
        ),
        .testTarget(
            name: "NKWalkCoreTests",
            dependencies: ["NKWalkCore"],
            path: "Tests/NKWalkCoreTests"
        )
    ]
)
