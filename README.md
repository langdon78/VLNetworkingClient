# VL (Very Light 🪶) Networking Client

A modern, Swift-native networking client built with async/await, comprehensive interceptor support, and robust error handling.

## Features

- **Modern Swift Concurrency**: Built from the ground up with async/await and actors for thread-safe operations
- **Interceptor Chain**: Flexible request/response interceptor system for authentication, caching, logging, and rate limiting
- **Comprehensive Error Handling**: Detailed error types for different network conditions with localized descriptions
- **File Operations**: Built-in support for efficient file uploads and downloads
- **Protocol-Based Design**: Highly testable and mockable architecture
- **Retry Logic**: Configurable retry mechanisms with exponential backoff
- **Type Safety**: Full Codable support with customizable encoders and decoders

## Requirements

- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 6.0+ / visionOS 1.0+
- Swift 6.1+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add VLNetworkingClient to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VLNetworkingClient.git", from: "1.0.0")
]
```

## Quick Start

### Basic Usage

```swift
import VLNetworkingClient

// Create a client
let client = AsyncNetworkClient()

// Define your data model
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// Make a GET request
let config = RequestConfiguration(
    url: URL(string: "https://jsonplaceholder.typicode.com/users/1")!,
    method: .GET
)

do {
    let response: NetworkResponse<User> = try await client.request(config)
    if let user = response.data {
        print("User: \(user.name)")
    }
} catch {
    print("Request failed: \(error)")
}
```

### POST Request with JSON Body

```swift
struct CreateUserRequest: Codable {
    let name: String
    let email: String
}

let newUser = CreateUserRequest(name: "John Doe", email: "john@example.com")
let config = try RequestConfiguration(
    url: URL(string: "https://jsonplaceholder.typicode.com/users")!,
    method: .POST
).withEncodableBody(newUser)

let response: NetworkResponse<User> = try await client.request(config)
```

## Common Use Cases

### 1. Adding Authentication

```swift
// Implement the TokenManager protocol
class MyTokenManager: TokenManager {
    private var currentToken: String?
    
    func getValidToken() async throws -> String {
        if let token = currentToken {
            return token
        }
        return try await refreshToken()
    }
    
    func refreshToken() async throws -> String {
        // Your token refresh logic here
        let newToken = "refreshed-token"
        currentToken = newToken
        return newToken
    }
}

// Add authentication interceptor
let tokenManager = MyTokenManager()
let authInterceptor = AuthenticationInterceptor(tokenManager: tokenManager)
let authenticatedClient = await client.with(interceptor: authInterceptor)
```

### 2. Request Logging

```swift
// Implement the Logger protocol
struct ConsoleLogger: Logger {
    func log(level: LogLevel, message: String) {
        print("[\(level)] \(message)")
    }
}

// Add logging interceptor
let logger = ConsoleLogger()
let loggingInterceptor = LoggingInterceptor(logger: logger)
let loggingClient = await client.with(interceptor: loggingInterceptor)
```

### 3. File Upload

```swift
let fileURL = Bundle.main.url(forResource: "document", withExtension: "pdf")!

let config = RequestConfiguration(
    url: URL(string: "https://api.example.com/upload")!,
    method: .POST,
    headers: ["Content-Type": "application/pdf"]
)

let response = try await client.uploadFile(config, from: fileURL)
print("Upload completed with status: \(response.statusCode)")
```

### 4. File Download

```swift
let config = RequestConfiguration(
    url: URL(string: "https://example.com/large-file.zip")!
)

let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let destinationURL = documentsURL.appendingPathComponent("downloaded-file.zip")

let response = try await client.downloadFile(config, to: destinationURL)
print("File downloaded to: \(response.data)")
```

### 5. Chaining Multiple Interceptors

```swift
let fullyConfiguredClient = await client
    .with(interceptor: AuthenticationInterceptor(tokenManager: tokenManager))
    .with(interceptor: LoggingInterceptor(logger: logger))
    .with(interceptor: CacheInterceptor(cachePolicy: .returnCacheDataElseLoad))
    .with(interceptor: RateLimitInterceptor(requestsPerSecond: 10))

// All requests through this client will be authenticated, logged, cached, and rate-limited
let response: NetworkResponse<[User]> = try await fullyConfiguredClient.request(usersConfig)
```

### 6. Error Handling

```swift
do {
    let response: NetworkResponse<User> = try await client.request(config)
    // Handle success
} catch NetworkError.unauthorized {
    // Handle 401 - redirect to login
} catch NetworkError.notFound {
    // Handle 404 - show not found message
} catch NetworkError.tooManyRequests {
    // Handle 429 - show rate limit message
} catch NetworkError.decodingError(let error) {
    // Handle JSON parsing errors
    print("Failed to parse response: \(error)")
} catch NetworkError.noInternetConnection {
    // Handle offline state
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
```

## Built-in Interceptors

- **AuthenticationInterceptor**: Automatically adds authentication tokens to requests
- **LoggingInterceptor**: Logs request and response details for debugging
- **CacheInterceptor**: Provides intelligent response caching
- **RateLimitInterceptor**: Prevents exceeding API rate limits

## Testing

VLNetworkingClient's protocol-based design makes it easy to test:

```swift
// Create a mock client for testing
final class MockNetworkClient: AsyncNetworkClientProtocol {
    var mockResponses: [String: Any] = [:]
    
    func request<T: Codable>(
        _ config: RequestConfiguration,
        decoder: ResponseBodyDecoder = JSONDecoder()
    ) async throws -> NetworkResponse<T> {
        // Return mock data based on request
    }
    
    // Implement other required methods...
}

// Use in your tests
let mockClient = MockNetworkClient()
let userService = UserService(client: mockClient)
```

## Documentation

For comprehensive documentation, examples, and advanced usage patterns, see the [DocC documentation](Sources/VLNetworkingClient/VLNetworkingClient.docc/VLNetworkingClient.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.