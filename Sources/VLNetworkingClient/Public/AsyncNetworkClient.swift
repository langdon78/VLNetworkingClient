//
//  AsyncClient.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/14/25.
//

import Foundation

/// A thread-safe, async/await-based network client with interceptor support.
///
/// `AsyncNetworkClient` provides a modern Swift networking interface with comprehensive
/// support for interceptors, retry logic, and various HTTP operations including file uploads and downloads.
///
/// ## Usage
///
/// ```swift
/// let client = AsyncNetworkClient()
/// 
/// // Add interceptors for cross-cutting concerns
/// let configuredClient = await client
///     .with(interceptor: AuthenticationInterceptor(tokenManager: tokenManager))
///     .with(interceptor: LoggingInterceptor(logger: logger))
/// 
/// // Make requests
/// let config = RequestConfiguration(url: url, method: .GET)
/// let response: NetworkResponse<User> = try await configuredClient.request(config)
/// ```
public final actor AsyncNetworkClient: AsyncNetworkClientProtocol {
    private let session: URLSessionProtocol
    private let interceptorChain: InterceptorChainProtocol
    
    /// Creates a new network client with the specified session and interceptor chain.
    /// - Parameters:
    ///   - session: The URL session to use for network requests.
    ///   - interceptorChain: The interceptor chain for processing requests and responses. Defaults to an empty chain.
    public init(
        session: URLSessionProtocol,
        interceptorChain: InterceptorChain = InterceptorChain()
    ) {
        self.session = session
        self.interceptorChain = interceptorChain
    }
    
    /// Adds an interceptor to the client's interceptor chain.
    /// 
    /// Interceptors allow you to modify requests before they are sent and responses before they are returned.
    /// Common use cases include authentication, logging, caching, and rate limiting.
    /// 
    /// - Parameter interceptor: The interceptor to add to the chain.
    /// - Returns: The same client instance with the interceptor added.
    public func with<T>(interceptor: T) async -> Self where T: RequestInterceptor {
        let updatedSelf = self
        await updatedSelf.interceptorChain.add(interceptor)
        return updatedSelf
    }
    
    // MARK: - Request Methods
    
    /// Performs a network request and decodes the response to the specified type.
    /// 
    /// - Parameters:
    ///   - config: The request configuration containing URL, method, headers, and other settings.
    ///   - decoder: The decoder to use for parsing the response body. Defaults to `JSONDecoder()`.
    /// - Returns: A `NetworkResponse` containing the decoded data and HTTP response.
    /// - Throws: `NetworkError` for various network and decoding failures.
    public func request<T: Codable>(
        _ config: RequestConfiguration,
        decoder: ResponseBodyDecoder = JSONDecoder()
    ) async throws -> NetworkResponse<T> {
        let networkResponse = try await request(config)
        let (data, response) = (networkResponse.data, networkResponse.response)
        
        do {
            if let data {
                let decodedData = try decoder.decode(T.self, from: data)
                return NetworkResponse(data: decodedData, response: response)
            }
        } catch {
            throw NetworkError.decodingError(error)
        }
        return NetworkResponse(data: nil, response: networkResponse.response)
    }
    
    /// Performs a network request and returns the raw response data.
    /// 
    /// - Parameter config: The request configuration containing URL, method, headers, and other settings.
    /// - Returns: A `NetworkResponse` containing the raw data and HTTP response.
    /// - Throws: `NetworkError` for various network failures.
    public func request(
        _ config: RequestConfiguration
    ) async throws -> NetworkResponse<Data> {
        try await withRetry(config.retryCount, delay: config.retryDelay) {
            try await performRequest(request: config.urlRequest)
        }
    }
    
    /// Downloads a file from the network to a specified destination.
    /// 
    /// - Parameters:
    ///   - config: The request configuration for the download.
    ///   - destination: The local URL where the file should be saved.
    /// - Returns: A `NetworkResponse` containing the destination URL and HTTP response.
    /// - Throws: `NetworkError` for network failures or file system errors.
    public func downloadFile(_ config: RequestConfiguration, to destination: URL) async throws -> NetworkResponse<URL> {
        let urlRequest = config.urlRequest
        
        return try await withRetry(config.retryCount, delay: config.retryDelay) {
            let (tempURL, response) = try await session.download(for: urlRequest, delegate: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }
            
            try validateResponse(httpResponse, data: nil)
            
            // Move file to destination
            try FileManager.default.moveItem(at: tempURL, to: destination)
            
            return NetworkResponse(data: destination, response: httpResponse)
        }
    }
    
    /// Uploads a file to the network.
    /// 
    /// - Parameters:
    ///   - config: The request configuration for the upload.
    ///   - fileURL: The local URL of the file to upload.
    /// - Returns: A `NetworkResponse` containing the server response data and HTTP response.
    /// - Throws: `NetworkError` for network failures or file system errors.
    public func uploadFile(_ config: RequestConfiguration, from fileURL: URL) async throws -> NetworkResponse<Data> {
        let urlRequest = config.urlRequest
        
        return try await withRetry(config.retryCount, delay: config.retryDelay) {
            let (data, response) = try await session.upload(for: urlRequest, fromFile: fileURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }
            
            try validateResponse(httpResponse, data: data)
            
            return NetworkResponse(data: data, response: httpResponse)
        }
    }
    
    // MARK: Private Methods
    private func performRequest(
        request: URLRequest,
        currentRetryCount: Int = 1
    ) async throws -> NetworkResponse<Data> {
        var interceptedRequest: URLRequest
        do {
            interceptedRequest = try await interceptorChain.interceptRequest(request)
        } catch RequestInterceptorError.cached(let cachedData) {
            return NetworkResponse(data: cachedData, response: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        
        let (data, response) = try await session.data(for: interceptedRequest, delegate: nil)
        
        let responseData = try await interceptorChain.interceptResponse(
            response,
            data: data
        )
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(URLError(.badServerResponse))
        }
        
        try validateResponse(httpResponse, data: responseData)
        
        return NetworkResponse(data: responseData, response: httpResponse)
    }
    
    private func validateResponse(_ response: HTTPURLResponse, data: Data?) throws {
         let statusCode = response.statusCode
         
         switch statusCode {
         case 200...299:
             return // Success
         case 401:
             throw NetworkError.unauthorized
         case 403:
             throw NetworkError.forbidden
         case 404:
             throw NetworkError.notFound
         case 408:
             throw NetworkError.requestTimeout
         case 429:
             throw NetworkError.tooManyRequests
         case 500...599:
             throw NetworkError.serverUnavailable
         default:
             throw NetworkError.httpError(statusCode: statusCode, data: data)
         }
    }
    
    private func withRetry<T: Sendable>(
        _ maxRetries: Int,
        delay: TimeInterval,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if shouldNotRetry(error: error) || attempt == maxRetries {
                    throw error
                }
                
                // Wait before retrying with exponential backoff
                let retryDelay = delay * Double(attempt + 1)
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NetworkError.unknown(URLError(.unknown))
    }
    
    private func shouldNotRetry(error: Error) -> Bool {
        switch error {
        case NetworkError.forbidden,
            NetworkError.notFound,
            NetworkError.decodingError,
            NetworkError.unauthorized:
            return true
        case let NetworkError.httpError(statusCode, _):
            return statusCode >= 400 && statusCode < 500 // Client errors
        case URLError.badURL, URLError.unsupportedURL, URLError.cancelled:
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Extensions
extension AsyncNetworkClient {
    /// Convenience method for making POST requests with JSON bodies.
    /// 
    /// - Parameters:
    ///   - url: The URL to send the POST request to.
    ///   - body: The Codable object to encode as the request body.
    ///   - headers: Additional headers to include in the request.
    ///   - encoder: The encoder to use for the request body. Defaults to `JSONEncoder()`.
    /// - Returns: A `NetworkResponse` containing the decoded response.
    /// - Throws: `NetworkError` for network or encoding/decoding failures.
    func post<T: Codable, U: Codable>(
        to url: URL,
        body: T,
        headers: [String: String] = [:],
        encoder: RequestBodyEncoder = JSONEncoder()
    ) async throws -> NetworkResponse<U> {
        let bodyData = try encoder.encode(body)
        let config = RequestConfiguration(
            url: url,
            method: .POST,
            headers: headers,
            body: bodyData
        )
        return try await request(config)
    }
    
    /// Convenience method for making GET requests.
    /// 
    /// - Parameters:
    ///   - url: The URL to send the GET request to.
    ///   - headers: Additional headers to include in the request.
    /// - Returns: A `NetworkResponse` containing the decoded response.
    /// - Throws: `NetworkError` for network or decoding failures.
    func get<T: Codable & Sendable>(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> NetworkResponse<T> {
        let config = RequestConfiguration(
            url: url,
            method: .GET,
            headers: headers
        )
        return try await request(config)
    }
    
    /// Convenience method for making PUT requests with JSON bodies.
    /// 
    /// - Parameters:
    ///   - url: The URL to send the PUT request to.
    ///   - body: The Codable object to encode as the request body.
    ///   - headers: Additional headers to include in the request.
    ///   - encoder: The encoder to use for the request body. Defaults to `JSONEncoder()`.
    /// - Returns: A `NetworkResponse` containing the decoded response.
    /// - Throws: `NetworkError` for network or encoding/decoding failures.
    func put<T: Codable, U: Codable>(
        to url: URL,
        body: T,
        headers: [String: String] = [:],
        encoder: RequestBodyEncoder = JSONEncoder()
    ) async throws -> NetworkResponse<U> {
        let bodyData = try encoder.encode(body)
        let config = RequestConfiguration(
            url: url,
            method: .PUT,
            headers: headers,
            body: bodyData
        )
        return try await request(config)
    }
    
    /// Convenience method for making DELETE requests.
    /// 
    /// - Parameters:
    ///   - url: The URL to send the DELETE request to.
    ///   - headers: Additional headers to include in the request.
    /// - Returns: A `NetworkResponse` containing the raw response data.
    /// - Throws: `NetworkError` for network failures.
    func delete(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> NetworkResponse<Data> {
        let config = RequestConfiguration(
            url: url,
            method: .DELETE,
            headers: headers
        )
        return try await request(config)
    }
}
