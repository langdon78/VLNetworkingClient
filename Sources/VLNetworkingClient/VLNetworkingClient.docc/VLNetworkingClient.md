# ``VLNetworkingClient``

A modern, Swift-based networking client with comprehensive interceptor support, caching, authentication, and rate limiting.

## Overview

VLNetworkingClient is a powerful networking library designed for modern Swift applications. It provides a clean, async/await-based API with comprehensive interceptor support for cross-cutting concerns like authentication, caching, logging, and rate limiting.

### Key Features

- **Async/await Support**: Built from the ground up with Swift's modern concurrency features
- **Interceptor Chain**: Flexible request/response interceptor system for authentication, caching, logging, and rate limiting
- **Actor-based Thread Safety**: Uses Swift actors to ensure thread-safe networking operations
- **Comprehensive Error Handling**: Detailed error types for different network conditions
- **File Operations**: Built-in support for file uploads and downloads
- **Retry Logic**: Configurable retry mechanisms with exponential backoff
- **Protocol-based Design**: Highly testable and mockable architecture

## Getting Started

### Basic Usage

```swift
import VLNetworkingClient

// Create a client
let client = AsyncNetworkClient()

// Make a simple GET request
let config = RequestConfiguration(
    url: URL(string: "https://api.example.com/users")!,
    method: .GET
)

do {
    let response: NetworkResponse<[User]> = try await client.request(config)
    print("Users: \(response.data)")
} catch {
    print("Error: \(error)")
}
```

### Adding Interceptors

```swift
// Add authentication and logging interceptors
let authenticatedClient = await client
    .with(interceptor: AuthenticationInterceptor(tokenManager: myTokenManager))
    .with(interceptor: LoggingInterceptor(logger: myLogger))

// Use the configured client
let response = try await authenticatedClient.request(config)
```

## Topics

### Essential Types

- ``AsyncNetworkClient``
- ``RequestConfiguration``
- ``NetworkResponse``
- ``NetworkError``

### Protocols

- ``AsyncNetworkClientProtocol``
- ``RequestInterceptor``
- ``TokenManager``
- ``Logger``
- ``RequestBodyEncoder``
- ``ResponseBodyDecoder``

### Configuration

- ``HTTPMethod``
- ``CachePolicy``

### Interceptors

- ``AuthenticationInterceptor``
- ``CacheInterceptor``
- ``LoggingInterceptor``
- ``RateLimitInterceptor``

### Supporting Types

- ``InterceptorChainFactory``
- ``StringDecoder``