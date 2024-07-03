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
The [KeyChainStorageService](https://eu-digital-identity-wallet.github.io/eudi-lib-ios-wallet-storage/documentation/walletstorage/keychainstorageservice) class provides functionality for [document](https://eu-digital-identity-wallet.github.io/eudi-lib-ios-wallet-storage/documentation/walletstorage/document) storage in iOS keychain.
```swift
    // serviceName - the name of the service (container) to be used for keychain storage
    // accessGroup - the access group to be used for keychain storage. If nil, the default access group will be used. It can be not null to share storage access with other applications.
	let keyChainObj = KeyChainStorageService(serviceName: serviceName, accessGroup: accessGroup)
```	
### Documentation
Detail documentation reference is provided [here](https://eu-digital-identity-wallet.github.io/eudi-lib-ios-wallet-storage/documentation/walletstorage/)


### Disclaimer
The released software is a initial development release version: 
-  The initial development release is an early endeavor reflecting the efforts of a short timeboxed period, and by no means can be considered as the final product.  
-  The initial development release may be changed substantially over time, might introduce new features but also may change or remove existing ones, potentially breaking compatibility with your existing code.
-  The initial development release is limited in functional scope.
-  The initial development release may contain errors or design flaws and other problems that could cause system or other failures and data loss.
-  The initial development release has reduced security, privacy, availability, and reliability standards relative to future releases. This could make the software slower, less reliable, or more vulnerable to attacks than mature software.
-  The initial development release is not yet comprehensively documented. 
-  Users of the software must perform sufficient engineering and additional testing in order to properly evaluate their application and determine whether any of the open-sourced components is suitable for use in that application.
-  We strongly recommend to not put this version of the software into production use.
-  Only the latest version of the software will be supported

### License details

Copyright (c) 2023 European Commission

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
