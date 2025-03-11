// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WalletStorage",
    defaultLocalization: "en",
	platforms: [.macOS(.v12), .iOS(.v15), .watchOS(.v9)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library( 
            name: "WalletStorage",
            targets: ["WalletStorage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.3"),
		.package(url: "https://github.com/eu-digital-identity-wallet/eudi-lib-ios-iso18013-data-model.git", exact: "0.5.6"),
		],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WalletStorage", 
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
								.product(name: "MdocDataModel18013", package: "eudi-lib-ios-iso18013-data-model"),
            ]),
        .testTarget(
            name: "WalletStorageTests",
            dependencies: ["WalletStorage"]),
    ]
)
