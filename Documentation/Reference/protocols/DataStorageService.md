**PROTOCOL**

# `DataStorageService`

```swift
public protocol DataStorageService
```

Data storage protocol

## Properties
### `serviceName`

```swift
var serviceName: String
```

### `accessGroup`

```swift
var accessGroup: String?
```

## Methods
### `loadDocument(id:)`

```swift
func loadDocument(id: String) throws -> Document?
```

### `loadDocuments()`

```swift
func loadDocuments() throws -> [Document]?
```

### `saveDocument(_:)`

```swift
func saveDocument(_ document: Document) throws
```

### `deleteDocument(id:)`

```swift
func deleteDocument(id: String) throws
```

### `deleteDocuments()`

```swift
func deleteDocuments() throws
```
