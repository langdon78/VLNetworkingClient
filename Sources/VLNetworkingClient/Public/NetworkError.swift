//
//  NetworkError.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/14/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Network Errors

/// Comprehensive error types for network operations.
///
/// `NetworkError` provides detailed error information for various network failure scenarios,
/// including HTTP errors, connectivity issues, and data processing failures.
///
/// ## Common Error Cases
///
/// - ``invalidURL``: The provided URL is malformed
/// - ``unauthorized``: HTTP 401 authentication required
/// - ``forbidden``: HTTP 403 access denied
/// - ``notFound``: HTTP 404 resource not found
/// - ``decodingError(_:)``: Failed to decode response data
/// - ``noInternetConnection``: Network connectivity unavailable
public enum NetworkError: Error, LocalizedError {
    /// The provided URL is invalid or malformed.
    case invalidURL
    
    /// No data was received in the response.
    case noData
    
    /// Failed to decode the response data.
    case decodingError(Error)
    
    /// HTTP error with status code and optional response data.
    case httpError(statusCode: Int, data: Data?)
    
    /// Request timed out.
    case requestTimeout
    
    /// No internet connection available.
    case noInternetConnection
    
    /// Server is unavailable (5xx errors).
    case serverUnavailable
    
    /// Unauthorized access (401).
    case unauthorized
    
    /// Forbidden access (403).
    case forbidden
    
    /// Resource not found (404).
    case notFound
    
    /// Too many requests (429). `retryAfter`, parsed from the response's
    /// `Retry-After` header if present, is the number of seconds the server
    /// asked the client to wait before retrying (supports both the
    /// delta-seconds and HTTP-date forms per RFC 7231 §7.1.3). `nil` if the
    /// server didn't send one — not every API does (Discogs, for one,
    /// doesn't), so callers should fall back to their own default backoff.
    case tooManyRequests(retryAfter: TimeInterval?)
    
    /// Unknown error with underlying error information.
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .requestTimeout:
            return "Request timeout"
        case .noInternetConnection:
            return "No internet connection"
        case .serverUnavailable:
            return "Server unavailable"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Forbidden access"
        case .notFound:
            return "Resource not found"
        case .tooManyRequests(let retryAfter):
            if let retryAfter {
                return "Too many requests (retry after \(retryAfter)s)"
            }
            return "Too many requests"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return String(reflecting: lhsError) == String(reflecting: rhsError)
        case
            (.notFound, .notFound),
            (.invalidURL, .invalidURL),
            (.noData, .noData),
            (.requestTimeout, .requestTimeout),
            (.noInternetConnection, .noInternetConnection),
            (.serverUnavailable, .serverUnavailable),
            (.unauthorized, .unauthorized),
            (.forbidden, .forbidden):
            return true
        case (.tooManyRequests(let lhsRetryAfter), .tooManyRequests(let rhsRetryAfter)):
            return lhsRetryAfter == rhsRetryAfter
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return String(reflecting: lhsError) == String(reflecting: rhsError)
        case (.httpError(let lhsStatusCode, let lhsData), .httpError(let rhsStatusCode, let rhsData)):
            return lhsStatusCode == rhsStatusCode && lhsData == rhsData
        default:
            return false
        }
    }
}

public enum InterceptorError: Error {
    case cancelled
    case cached(Data)
    case shouldRetryRequest
}

extension InterceptorError: Equatable {}
