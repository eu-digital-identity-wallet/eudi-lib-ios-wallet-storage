**CLASS**

# `KeyChainStorageService`

**Contents**

- [Properties](#properties)
  - `serviceName`
  - `accessGroup`
- [Methods](#methods)
  - `init(serviceName:accessGroup:)`
  - `loadDocument(id:)`
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
public var serviceName: String
```

### `accessGroup`

```swift
public var accessGroup: String?
```

## Methods
### `init(serviceName:accessGroup:)`

```swift
public init(serviceName: String, accessGroup: String? = nil)
```

### `loadDocument(id:)`

```swift
public func loadDocument(id: String) throws -> Document?
```

Gets the secret document by id passed in parameter
- Parameter id: Document identifier
- Returns: The document if exists

#### Parameters

| Name | Description |
| ---- | ----------- |
| id | Document identifier |

### `loadDocuments()`

```swift
public func loadDocuments() throws -> [Document]?
```

Gets all documents
- Parameters:
- Returns: The documents stored in keychain under the serviceName

### `saveDocument(_:)`

```swift
public func saveDocument(_ document: Document) throws
```

Save the secret to keychain
Note: the value passed in will be zeroed out after the secret is saved
- Parameters:
  - document: The document to save

#### Parameters

| Name | Description |
| ---- | ----------- |
| document | The document to save |

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