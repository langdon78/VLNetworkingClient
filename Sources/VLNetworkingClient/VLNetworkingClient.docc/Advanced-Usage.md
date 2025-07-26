# Advanced Usage

Explore advanced features and patterns for complex networking scenarios.

## Overview

This guide covers advanced usage patterns for VLNetworkingClient, including custom configurations, error recovery strategies, testing approaches, and performance optimization techniques.

## Custom URL Sessions

Use custom URL sessions for specialized requirements:

```swift
// Custom session with specific configuration
let sessionConfig = URLSessionConfiguration.default
sessionConfig.timeoutIntervalForRequest = 60
sessionConfig.timeoutIntervalForResource = 300
sessionConfig.httpMaximumConnectionsPerHost = 6

let customSession = URLSession(configuration: sessionConfig)
let client = AsyncNetworkClient(session: customSession)
```

## Advanced Error Handling

### Retry Strategies

Implement sophisticated retry logic:

```swift
func makeRequestWithCustomRetry<T: Codable>(
    config: RequestConfiguration,
    client: AsyncNetworkClient
) async throws -> NetworkResponse<T> {
    var lastError: Error?
    let maxRetries = 5
    
    for attempt in 0..<maxRetries {
        do {
            return try await client.request(config)
        } catch NetworkError.tooManyRequests {
            // Exponential backoff for rate limiting
            let delay = pow(2.0, Double(attempt)) 
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        } catch NetworkError.serverUnavailable {
            // Linear backoff for server errors
            try await Task.sleep(nanoseconds: UInt64(Double(attempt + 1) * 1_000_000_000))
        } catch {
            lastError = error
            break // Don't retry for client errors
        }
    }
    
    throw lastError ?? NetworkError.unknown(URLError(.unknown))
}
```

### Circuit Breaker Pattern

Implement circuit breaker for failing services:

```swift
actor CircuitBreaker {
    private var failureCount = 0
    private var lastFailureTime: Date?
    private var state: State = .closed
    
    enum State {
        case closed, open, halfOpen
    }
    
    func canExecute() -> Bool {
        switch state {
        case .closed:
            return true
        case .open:
            let timeout: TimeInterval = 60 // 1 minute
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > timeout {
                state = .halfOpen
                return true
            }
            return false
        case .halfOpen:
            return true
        }
    }
    
    func recordSuccess() {
        failureCount = 0
        state = .closed
        lastFailureTime = nil
    }
    
    func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
        
        if failureCount >= 3 {
            state = .open
        }
    }
}
```

## Testing Strategies

### Protocol-Based Testing

VLNetworkingClient's protocol-based design enables comprehensive testing:

```swift
// Mock implementation for testing
final class MockNetworkClient: AsyncNetworkClientProtocol {
    var responses: [String: Any] = [:]
    var errors: [String: Error] = [:]
    
    func request<T: Codable>(
        _ config: RequestConfiguration,
        decoder: ResponseBodyDecoder = JSONDecoder()
    ) async throws -> NetworkResponse<T> {
        let key = "\(config.method.description)-\(config.url.absoluteString)"
        
        if let error = errors[key] {
            throw error
        }
        
        if let responseData = responses[key] as? T {
            let httpResponse = HTTPURLResponse(
                url: config.url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return NetworkResponse(data: responseData, response: httpResponse)
        }
        
        throw NetworkError.noData
    }
    
    // Implement other required methods...
}

// Usage in tests
func testUserFetching() async throws {
    let mockClient = MockNetworkClient()
    mockClient.responses["GET-https://api.example.com/user"] = User(id: 1, name: "Test User")
    
    let service = UserService(client: mockClient)
    let user = try await service.fetchUser(id: 1)
    
    XCTAssertEqual(user.name, "Test User")
}
```

### Interceptor Testing

Test interceptors in isolation:

```swift
func testAuthenticationInterceptor() async throws {
    let tokenManager = MockTokenManager()
    tokenManager.token = "test-token"
    
    let interceptor = AuthenticationInterceptor(tokenManager: tokenManager)
    
    var request = URLRequest(url: URL(string: "https://api.example.com")!)
    request = try await interceptor.interceptRequest(request)
    
    XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
}
```

## Performance Optimization

### Connection Pooling

Configure connection pooling for high-throughput scenarios:

```swift
let config = URLSessionConfiguration.default
config.httpMaximumConnectionsPerHost = 10
config.requestCachePolicy = .useProtocolCachePolicy
config.urlCache = URLCache(
    memoryCapacity: 20 * 1024 * 1024,  // 20 MB
    diskCapacity: 100 * 1024 * 1024,   // 100 MB
    diskPath: nil
)

let optimizedSession = URLSession(configuration: config)
let client = AsyncNetworkClient(session: optimizedSession)
```

### Batch Operations

Handle multiple requests efficiently:

```swift
func fetchMultipleUsers(ids: [Int], client: AsyncNetworkClient) async throws -> [User] {
    return try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask {
                let config = RequestConfiguration(
                    url: URL(string: "https://api.example.com/users/\(id)")!
                )
                let response: NetworkResponse<User> = try await client.request(config)
                return response.data!
            }
        }
        
        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
}
```

### Memory Management

For large-scale applications, monitor memory usage:

```swift
// Use weak references for cached clients
class NetworkManager {
    private weak var cachedClient: AsyncNetworkClient?
    
    func getClient() async -> AsyncNetworkClient {
        if let client = cachedClient {
            return client
        }
        
        let newClient = await AsyncNetworkClient()
            .with(interceptor: authInterceptor)
            .with(interceptor: loggingInterceptor)
        
        cachedClient = newClient
        return newClient
    }
}
```

## Custom Protocols

Extend functionality with custom protocols:

```swift
protocol NetworkClientWithMetrics: AsyncNetworkClientProtocol {
    var requestCount: Int { get async }
    var averageResponseTime: TimeInterval { get async }
}

extension AsyncNetworkClient: NetworkClientWithMetrics {
    var requestCount: Int {
        get async {
            // Implementation would track request metrics
            return 0
        }
    }
    
    var averageResponseTime: TimeInterval {
        get async {
            // Implementation would calculate average response time
            return 0.0
        }
    }
}
```

## Debugging and Monitoring

### Request/Response Logging

Implement comprehensive logging:

```swift
struct DetailedLogger: Logger {
    func log(level: LogLevel, message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level)] \(message)")
    }
}

let debugClient = await client.with(interceptor: LoggingInterceptor(logger: DetailedLogger()))
```

### Performance Metrics

Track performance metrics:

```swift
actor PerformanceTracker {
    private var requestTimes: [TimeInterval] = []
    
    func recordRequestTime(_ time: TimeInterval) {
        requestTimes.append(time)
        
        // Keep only recent measurements
        if requestTimes.count > 1000 {
            requestTimes.removeFirst()
        }
    }
    
    var averageRequestTime: TimeInterval {
        guard !requestTimes.isEmpty else { return 0 }
        return requestTimes.reduce(0, +) / Double(requestTimes.count)
    }
}
```