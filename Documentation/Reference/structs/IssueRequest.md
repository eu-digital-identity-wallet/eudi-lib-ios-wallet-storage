**STRUCT**

# `IssueRequest`

**Contents**

- [Properties](#properties)
  - `secureKey`
  - `publicKey`
  - `certificate`
- [Methods](#methods)
  - `init(certificate:savedKey:)`
  - `signData(_:)`

```swift
public struct IssueRequest
```

Issue request structure

## Properties
### `secureKey`

### `publicKey`

### `certificate`

```swift
let certificate: SecCertificate?
```

## Methods
### `init(certificate:savedKey:)`

```swift
public init(certificate: SecCertificate? = nil, savedKey: Data? = nil) throws
```

Initialize issue request
- Parameters:
  - certificate: Root certificate (optional)
  - savedKey: saved key representation (optional)

#### Parameters

| Name | Description |
| ---- | ----------- |
| certificate | Root certificate (optional) |
| savedKey | saved key representation (optional) |

### `signData(_:)`

Sign data with ``secureKey``
- Parameter data: Data to be signed
- Returns: DER representation of signture for SHA256  hash
