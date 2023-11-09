**STRUCT**

# `StorageError`

**Contents**

- [Properties](#properties)
  - `description`
  - `code`
  - `errorDescription`
- [Methods](#methods)
  - `init(description:code:)`
  - `==(_:_:)`

```swift
public struct StorageError: LocalizedError
```

## Properties
### `description`

```swift
var description: String
```

### `code`

```swift
var code: Int
```

### `errorDescription`

```swift
public var errorDescription: String?
```

## Methods
### `init(description:code:)`

```swift
init(description: String, code: Int = 0)
```

### `==(_:_:)`

```swift
public static func ==(lhs: StorageError, rhs: StorageError) -> Bool
```
