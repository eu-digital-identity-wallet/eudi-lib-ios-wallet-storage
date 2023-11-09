**STRUCT**

# `Document`

**Contents**

- [Properties](#properties)
  - `id`
  - `docType`
  - `data`
  - `createdAt`
  - `modifiedAt`
- [Methods](#methods)
  - `init(id:docType:data:createdAt:modifiedAt:)`

```swift
public struct Document
```

wallet document structure

## Properties
### `id`

```swift
public var id: String = UUID().uuidString
```

### `docType`

```swift
public let docType: String
```

### `data`

```swift
public let data: Data
```

### `createdAt`

```swift
public let createdAt: Date
```

### `modifiedAt`

```swift
public let modifiedAt: Date?
```

## Methods
### `init(id:docType:data:createdAt:modifiedAt:)`

```swift
public init(id: String = UUID().uuidString, docType: String, data: Data, createdAt: Date, modifiedAt: Date? = nil)
```
