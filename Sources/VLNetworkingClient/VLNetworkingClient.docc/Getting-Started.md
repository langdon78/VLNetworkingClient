# Getting Started

Learn how to integrate and use VLNetworkingClient in your Swift projects.

## Overview

VLNetworkingClient is designed to make network operations in Swift apps simple, safe, and powerful. This guide will walk you through the basic setup and common usage patterns.

## Installation

### Swift Package Manager

Add VLNetworkingClient to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VLNetworkingClient.git", from: "1.0.0")
]
```

## Basic Setup

### Creating a Client

The simplest way to get started is to create an `AsyncNetworkClient`:

```swift
import VLNetworkingClient

let client = AsyncNetworkClient()
```

### Making Your First Request

Here's how to make a basic GET request:

```swift
let config = RequestConfiguration(
    url: URL(string: "https://jsonplaceholder.typicode.com/users")!,
    method: .GET
)

do {
    let response: NetworkResponse<[User]> = try await client.request(config)
    if let users = response.data {
        print("Retrieved \(users.count) users")
    }
} catch {
    print("Request failed: \(error)")
}
```

### Working with JSON

VLNetworkingClient automatically handles JSON encoding and decoding:

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// POST request with JSON body
let newUser = CreateUserRequest(name: "John Doe", email: "john@example.com")
let config = try RequestConfiguration(
    url: URL(string: "https://jsonplaceholder.typicode.com/users")!,
    method: .POST
).withEncodableBody(newUser)

let response: NetworkResponse<User> = try await client.request(config)
```

## Configuration Options

### Request Configuration

`RequestConfiguration` provides comprehensive control over your requests:

```swift
let config = RequestConfiguration(
    url: url,
    method: .POST,
    headers: ["Authorization": "Bearer \(token)"],
    timeoutInterval: 60.0,
    retryCount: 3,
    retryDelay: 0.5
)
```

### Error Handling

VLNetworkingClient provides detailed error information:

```swift
do {
    let response = try await client.request(config)
    // Handle success
} catch NetworkError.unauthorized {
    // Handle 401 errors
} catch NetworkError.notFound {
    // Handle 404 errors
} catch NetworkError.decodingError(let error) {
    // Handle JSON decoding errors
} catch {
    // Handle other errors
}
```

## Next Steps

- Learn about <doc:Interceptors> to add authentication, logging, and caching
- Explore <doc:File-Operations> for uploads and downloads
- See <doc:Advanced-Usage> for complex scenarios