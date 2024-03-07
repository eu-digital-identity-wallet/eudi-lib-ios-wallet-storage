# EUDI Wallet Storage library for iOS

:heavy_exclamation_mark: **Important!** Before you proceed, please read
the [EUDI Wallet Reference Implementation project description](https://github.com/eu-digital-identity-wallet/.github/blob/main/profile/reference-implementation.md)

----

# EUDI ISO 18013-5 iOS Wallet Storage library
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Swift](https://github.com/eu-digital-identity-wallet/eudi-lib-ios-wallet-storage/actions/workflows/swift.yml/badge.svg)](https://github.com/eu-digital-identity-wallet/eudi-lib-ios-wallet-storage/actions/workflows/swift.yml)
[![Lines of Code](https://sonarcloud.io/api/project_badges/measure?project=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage&metric=ncloc&token=830355e3188e340a2ac40960135f0418bdab2513)](https://sonarcloud.io/summary/new_code?id=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage)
[![Duplicated Lines (%)](https://sonarcloud.io/api/project_badges/measure?project=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage&metric=duplicated_lines_density&token=830355e3188e340a2ac40960135f0418bdab2513)](https://sonarcloud.io/summary/new_code?id=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage)
[![Reliability Rating](https://sonarcloud.io/api/project_badges/measure?project=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage&metric=reliability_rating&token=830355e3188e340a2ac40960135f0418bdab2513)](https://sonarcloud.io/summary/new_code?id=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage&metric=vulnerabilities&token=830355e3188e340a2ac40960135f0418bdab2513)](https://sonarcloud.io/summary/new_code?id=eu-digital-identity-wallet_eudi-lib-ios-wallet-storage)


The initial implementation provides keychain storage for wallet documents

## Getting Started
The [KeyChainStorageService](Documentation/Reference/classes/KeyChainStorageService.md) class provides functionality for [document](Documentation/Reference/structs/Document.md) storage in iOS keychain.
```swift
    // serviceName - the name of the service (container) to be used for keychain storage
    // accessGroup - the access group to be used for keychain storage. If nil, the default access group will be used. It can be not null to share storage access with other applications.
	let keyChainObj = KeyChainStorageService(serviceName: serviceName, accessGroup: accessGroup)
```	
