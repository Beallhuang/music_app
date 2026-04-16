// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MusicPlayer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MusicPlayer",
            targets: ["MusicPlayer"]),
    ],
    targets: [
        .target(
            name: "MusicPlayer",
            dependencies: []),
        .testTarget(
            name: "MusicPlayerTests",
            dependencies: ["MusicPlayer"]),
    ]
)
