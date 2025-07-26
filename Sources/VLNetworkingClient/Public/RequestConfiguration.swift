//
//  RequestConfiguration.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/14/25.
//

import Foundation

// MARK: - Request Configuration

/// Configuration object that encapsulates all parameters needed to make a network request.
///
/// `RequestConfiguration` provides a comprehensive way to configure HTTP requests including
/// URL, method, headers, body, timeout, and retry behavior.
///
/// ## Example
///
/// ```swift
/// let config = RequestConfiguration(
///     url: URL(string: "https://api.example.com/users")!,
///     method: .POST,
///     headers: ["Authorization": "Bearer token"],
///     retryCount: 3
/// )
/// ```
public struct RequestConfiguration: Sendable {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public var body: Data?
    public let timeoutInterval: TimeInterval
    public let retryCount: Int
    public let retryDelay: TimeInterval
    
    /// Creates a new request configuration.
    /// 
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - method: The HTTP method. Defaults to `.GET`.
    ///   - headers: HTTP headers. Defaults to standard JSON headers.
    ///   - body: Request body data. Defaults to `nil`.
    ///   - timeoutInterval: Request timeout in seconds. Defaults to 30.0.
    ///   - retryCount: Number of retry attempts. Defaults to 3.
    ///   - retryDelay: Initial delay between retries in seconds. Defaults to 0.1.
    public init(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = Self.defaultHeaders,
        body: Data? = nil,
        timeoutInterval: TimeInterval = 30.0,
        retryCount: Int = 3,
        retryDelay: TimeInterval = 0.1
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
        self.retryCount = retryCount
        self.retryDelay = retryDelay
    }
    
    /// Creates a new configuration with an encoded request body.
    /// 
    /// - Parameters:
    ///   - body: The encodable object to use as the request body.
    ///   - encoder: The encoder to use. Defaults to `JSONEncoder()`.
    /// - Returns: A new configuration with the encoded body.
    /// - Throws: Encoding errors from the encoder.
    public func withEncodableBody<
        RequestPayload: Encodable,
        Encoder: RequestBodyEncoder
    >(
        _ body: RequestPayload,
        using encoder: Encoder = JSONEncoder()
    ) throws -> Self {
        var configuration = self
        configuration.body = try encoder.encode(body)
        return configuration
    }
}

extension RequestConfiguration {
    public static let defaultHeaders: [String: String] =
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "\(#fileID.prefix(while: { $0 != "/" }))/1.0"
        ]
    
    /// Converts the configuration to a `URLRequest`.
    public var urlRequest: URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.description
        request.httpBody = body
        request.timeoutInterval = timeoutInterval
        
        headers.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}
