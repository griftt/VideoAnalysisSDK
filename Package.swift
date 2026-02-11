// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoAnalysisSDK",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "VideoAnalysisSDK",
            targets: ["VideoAnalysisSDK"]),
        .executable(
            name: "CompleteTest",
            targets: ["CompleteTest"]),
    ],
    targets: [
        .target(
            name: "VideoAnalysisSDK",
            dependencies: []),
        .executableTarget(
            name: "CompleteTest",
            dependencies: ["VideoAnalysisSDK"],
            path: "Examples",
            sources: ["RunCompleteTest.swift"]),
        .testTarget(
            name: "VideoAnalysisSDKTests",
            dependencies: ["VideoAnalysisSDK"]),
    ]
)
