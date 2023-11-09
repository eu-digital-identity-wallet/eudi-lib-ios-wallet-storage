**STRUCT**

# `IssueRequest`

**Contents**

- [Properties](#properties)
  - `secureKey`
  - `publicKey`
- [Methods](#methods)
  - `init(savedKey:)`
  - `signData(_:)`

```swift
public struct IssueRequest
```

Issue request structure

## Properties
### `secureKey`

### `publicKey`

DER representation of public key

## Methods
### `init(savedKey:)`

```swift
public init(savedKey: Data? = nil) throws
```

Initialize issue request
- Parameters:
  - savedKey: saved key representation (optional)

#### Parameters

| Name | Description |
| ---- | ----------- |
| savedKey | saved key representation (optional) |

### `signData(_:)`

Sign data with ``secureKey``
- Parameter data: Data to be signed
- Returns: DER representation of signture for SHA256  hash
