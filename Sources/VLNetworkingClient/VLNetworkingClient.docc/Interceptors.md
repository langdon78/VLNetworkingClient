# Interceptors

Add cross-cutting functionality to your network requests with interceptors.

## Overview

Interceptors in VLNetworkingClient provide a powerful way to modify requests before they're sent and responses before they're returned to your application. This enables clean separation of concerns for authentication, logging, caching, rate limiting, and other cross-cutting functionality.

## Built-in Interceptors

### Authentication Interceptor

Automatically adds authentication tokens to requests:

```swift
let tokenManager = MyTokenManager() // Implements TokenManager protocol
let authInterceptor = AuthenticationInterceptor(tokenManager: tokenManager)

let authenticatedClient = await client.with(interceptor: authInterceptor)
```

### Logging Interceptor

Logs request and response details for debugging:

```swift
let logger = MyLogger() // Implements Logger protocol
let loggingInterceptor = LoggingInterceptor(logger: logger)

let loggingClient = await client.with(interceptor: loggingInterceptor)
```

### Cache Interceptor

Provides intelligent response caching:

```swift
let cacheInterceptor = CacheInterceptor(
    cachePolicy: .returnCacheDataElseLoad,
    maxAge: 300 // 5 minutes
)

let cachingClient = await client.with(interceptor: cacheInterceptor)
```

### Rate Limit Interceptor

Prevents exceeding API rate limits:

```swift
let rateLimitInterceptor = RateLimitInterceptor(
    requestsPerSecond: 10,
    burstLimit: 50
)

let rateLimitedClient = await client.with(interceptor: rateLimitInterceptor)
```

## Chaining Interceptors

Interceptors can be chained to combine multiple behaviors:

```swift
let fullyConfiguredClient = await client
    .with(interceptor: authInterceptor)
    .with(interceptor: loggingInterceptor)
    .with(interceptor: cacheInterceptor)
    .with(interceptor: rateLimitInterceptor)
```

## Creating Custom Interceptors

Implement the `RequestInterceptor` protocol to create custom interceptors:

```swift
struct CustomHeaderInterceptor: RequestInterceptor {
    let customHeader: String
    let value: String
    
    func interceptRequest(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        modifiedRequest.setValue(value, forHTTPHeaderField: customHeader)
        return modifiedRequest
    }
    
    func interceptResponse(_ response: URLResponse, data: Data) async throws -> Data {
        // Optionally modify response data
        return data
    }
}

// Use the custom interceptor
let customInterceptor = CustomHeaderInterceptor(
    customHeader: "X-App-Version", 
    value: "1.0.0"
)
let customClient = await client.with(interceptor: customInterceptor)
```

## Interceptor Execution Order

Interceptors are executed in the order they're added:

1. **Request Processing**: First added → Last added
2. **Response Processing**: Last added → First added

This ensures proper nesting behavior, similar to middleware in web frameworks.

## Protocol Requirements

### TokenManager Protocol

For authentication interceptors:

```swift
protocol TokenManager: Actor {
    func getValidToken() async throws -> String
    func refreshToken() async throws -> String
}
```

### Logger Protocol

For logging interceptors:

```swift
protocol Logger: Sendable {
    func log(level: LogLevel, message: String)
}
```

## Best Practices

- **Order Matters**: Add authentication before logging to log authenticated requests
- **Error Handling**: Interceptors should handle their own errors gracefully
- **Performance**: Keep interceptor logic lightweight to avoid request delays
- **Testing**: Mock interceptors for unit testing by implementing the protocols