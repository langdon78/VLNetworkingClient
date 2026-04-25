//
//  NetworkResponse.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

// MARK: - Response Wrapper

/// A wrapper that contains the raw response data and HTTP response metadata.
///
/// `NetworkResponse` encapsulates the result of a network request. Callers decode
/// the raw `data` into their own model types using `decode(_:using:)`.
///
/// ## Usage
///
/// ```swift
/// let response = try await client.request(for: config)
/// let user = try response.decode(User.self)
///
/// print("Status: \(response.statusCode)")
/// print("Headers: \(response.headers)")
/// ```
public struct NetworkResponse: Sendable {
    /// The raw response bytes, if any were returned.
    public let data: Data?

    /// The data payload as a UTF-8 string, if available.
    public var stringData: String? {
        guard let data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The underlying HTTP response object.
    public let response: HTTPURLResponse

    /// The HTTP status code from the response.
    public let statusCode: Int

    /// All HTTP headers from the response.
    public let headers: [String: String]

    /// Creates a new network response.
    /// - Parameters:
    ///   - data: The raw response bytes.
    ///   - response: The HTTP response object.
    public init(data: Data?, response: HTTPURLResponse) {
        self.data = data
        self.response = response
        self.statusCode = response.statusCode
        self.headers = (response.allHeaderFields as? [String: String]) ?? [:]
    }
}

extension NetworkResponse {
    /// Decodes the response body into the specified type.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode into.
    ///   - decoder: The decoder to use. Defaults to `JSONDecoder()`.
    /// - Returns: The decoded value.
    /// - Throws: `NetworkError.noData` if the response body is empty,
    ///   or `NetworkError.decodingError` if decoding fails.
    public func decode<T: Decodable>(_ type: T.Type, using decoder: ResponseBodyDecoder = JSONDecoder()) throws -> T {
        guard let data else { throw NetworkError.noData }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
