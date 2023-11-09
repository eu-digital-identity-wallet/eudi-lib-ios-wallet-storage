**CLASS**

# `KeyChainStorageService`

**Contents**

- [Properties](#properties)
  - `serviceName`
  - `accessGroup`
- [Methods](#methods)
  - `loadDocument(id:)`
  - `init()`
  - `loadDocuments()`
  - `saveDocument(_:)`
  - `deleteDocument(id:)`
  - `deleteDocuments()`
  - `makeQuery(id:bAll:)`
  - `makeDocument(dict:)`

```swift
public class KeyChainStorageService: DataStorageService
```

Implements key-chain storage

## Properties
### `serviceName`

```swift
public var serviceName: String = "eudiw"
```

### `accessGroup`

```swift
public var accessGroup: String?
```

## Methods
### `loadDocument(id:)`

```swift
public func loadDocument(id: String) throws -> Document?
```

### `init()`

```swift
public init()
```

### `loadDocuments()`

```swift
public func loadDocuments() throws -> [Document]?
```

Gets the secret with the id passed in parameter
- Parameters:
  - label: The label  (docType) of the secret
- Returns: The secret

#### Parameters

| Name | Description |
| ---- | ----------- |
| label | The label  (docType) of the secret |

### `saveDocument(_:)`

```swift
public func saveDocument(_ document: Document) throws
```

Save the secret to keychain
Note: the value passed in will be zeroed out after the secret is saved
- Parameters:
  - id: The Id of the secret
  - accessGroup: The access group to use to save secret.
  - value: The value of the secret
  - label: label of the document

#### Parameters

| Name | Description |
| ---- | ----------- |
| id | The Id of the secret |
| accessGroup | The access group to use to save secret. |
| value | The value of the secret |
| label | label of the document |

### `deleteDocument(id:)`

```swift
public func deleteDocument(id: String) throws
```

Delete the secret from keychain
Note: the value passed in will be zeroed out after the secret is deleted
- Parameters:
  - id: The Id of the secret

#### Parameters

| Name | Description |
| ---- | ----------- |
| id | The Id of the secret |

### `deleteDocuments()`

```swift
public func deleteDocuments() throws
```

Delete all documents from keychain
Note: the value passed in will be zeroed out after the secret is deleted
- Parameters:
  - id: The Id of the secret

#### Parameters

| Name | Description |
| ---- | ----------- |
| id | The Id of the secret |

### `makeQuery(id:bAll:)`

```swift
func makeQuery(id: String?, bAll: Bool) -> [String: Any]
```

Make a query for a an item in keychain
- Parameters:
  - id: id
  - bAll: request all matching items
- Returns: The dictionary query

#### Parameters

| Name | Description |
| ---- | ----------- |
| id | id |
| bAll | request all matching items |

### `makeDocument(dict:)`

```swift
func makeDocument(dict: NSDictionary) -> Document
```

Make a document from a keychain item
- Parameter dict: keychain item returned as dictionary
- Returns: the document

#### Parameters

| Name | Description |
| ---- | ----------- |
| dict | keychain item returned as dictionary |