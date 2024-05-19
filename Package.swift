// swift-tools-version: 5.10
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
        .package(url: "https://github.com/alfianlosari/ChatGPTSwift.git", from: "2.2.0"),
        .package(url: "https://github.com/apple/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/alfianlosari/HighlighterSwift.git", branch: "main")
    ],
    targets: [
        .target(
            name: "ChatGPTUI",
            dependencies: [
                "ChatGPTSwift",
                .product(name: "Highlighter", package: "HighlighterSwift"),
                .product(name: "Markdown", package: "swift-markdown")
            ]),
        .testTarget(
            name: "ChatGPTUITests",
            dependencies: ["ChatGPTUI"]),
    ]
)
