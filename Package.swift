// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CustomBottomSheetLibrary",
    platforms: [
        .iOS(.v14) // 지원하는 최소 플랫폼 버전 설정
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CustomBottomSheetLibrary",
            targets: ["CustomBottomSheetLibrary"]),
    ],
    dependencies: [
        // 'KeyboardManagerLibrary' 추가
        .package(url: "https://github.com/1domybest/KeyboardManagerLibrary", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "CustomBottomSheetLibrary",
            dependencies: [
                .product(name: "KeyboardManager", package: "KeyboardManagerLibrary") // 올바르게 연결
            ]),
    ]
)
