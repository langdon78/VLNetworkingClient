//
//  NetworkResponse.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

// MARK: - Response Wrapper

/// A wrapper that contains both the response data and HTTP response information.
///
/// `NetworkResponse` encapsulates the result of a network request, providing access to
/// both the parsed response data and the underlying HTTP response metadata.
///
/// ## Usage
///
/// ```swift
/// let response: NetworkResponse<User> = try await client.request(config)
/// 
/// if let user = response.data {
///     print("User: \(user.name)")
/// }
/// 
/// print("Status: \(response.statusCode)")
/// print("Headers: \(response.headers)")
/// ```
public struct NetworkResponse<T: Sendable>: @unchecked Sendable {
    /// The parsed response data, if available.
    public let data: T?
    
    /// The underlying HTTP response object.
    public let response: HTTPURLResponse
    
    /// The HTTP status code from the response.
    public let statusCode: Int
    
    /// All HTTP headers from the response.
    public let headers: [AnyHashable: Any]
    
    /// Creates a new network response.
    /// - Parameters:
    ///   - data: The parsed response data.
    ///   - response: The HTTP response object.
    public init(data: T?, response: HTTPURLResponse) {
        self.data = data
        self.response = response
        self.statusCode = response.statusCode
        self.headers = response.allHeaderFields
    }
}
