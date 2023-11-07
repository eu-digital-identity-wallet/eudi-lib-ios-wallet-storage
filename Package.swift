// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WalletStorage",
    defaultLocalization: "en",
	platforms: [.macOS(.v12), .iOS(.v13), .watchOS(.v9)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library( 
            name: "WalletStorage",
            targets: ["WalletStorage"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WalletStorage"),
        .testTarget(
            name: "WalletStorageTests",
            dependencies: ["WalletStorage"]),
    ]
)
