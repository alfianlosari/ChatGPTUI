// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatGPTUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)],
    products: [
        .library(
            name: "ChatGPTUI",
            targets: ["ChatGPTUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/alfianlosari/ChatGPTSwift.git", from: "2.5.0"),
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.4.0"),
        .package(url: "https://github.com/alfianlosari/HighlighterSwift.git", from: "1.0.0"),
        .package(url: "https://github.com/alfianlosari/SiriWaveView.git", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "ChatGPTUI",
            dependencies: [
                "ChatGPTSwift",
                "SiriWaveView",
                .product(name: "Highlighter", package: "HighlighterSwift"),
                .product(name: "Markdown", package: "swift-markdown")
            ]),
        .testTarget(
            name: "ChatGPTUITests",
            dependencies: ["ChatGPTUI"]),
    ]
)
