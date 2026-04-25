//
//  AsyncClient.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/14/25.
//

import Foundation
import VLDebugLogger

/// A thread-safe, async/await-based network client with interceptor support.
///
/// `AsyncNetworkClient` handles transport: executing HTTP requests through an interceptor
/// chain and returning raw `NetworkResponse` values. Callers are responsible for decoding
/// the response body using `NetworkResponse.decode(_:using:)`.
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
/// // Make a request and decode
/// let config = RequestConfiguration(url: url, method: .GET)
/// let response = try await configuredClient.request(for: config)
/// let user = try response.decode(User.self)
/// ```
public final actor AsyncNetworkClient: AsyncNetworkClientProtocol {
    private let session: URLSessionProtocol
    private let interceptorChain: InterceptorChainProtocol
    private let logger: VLDebugLogger

    /// Creates a new network client with the specified session and interceptor chain.
    /// - Parameters:
    ///   - session: The URL session to use for network requests.
    ///   - interceptorChain: The interceptor chain for processing requests and responses.
    ///   - logger: The logger instance.
    public init(
        session: URLSessionProtocol = URLSession.shared,
        interceptorChain: InterceptorChain = InterceptorChain(),
        logger: VLDebugLogger = VLDebugLogger.shared
    ) {
        self.session = session
        self.interceptorChain = interceptorChain
        self.logger = logger
    }

    /// Adds an interceptor to the client's interceptor chain.
    ///
    /// - Parameter interceptor: The interceptor to add to the chain.
    /// - Returns: The same client instance with the interceptor added.
    public func with<T>(interceptor: T) async -> Self where T: Interceptor {
        let updatedSelf = self
        await updatedSelf.interceptorChain.add(interceptor)
        return updatedSelf
    }

    // MARK: - Request Methods

    /// Performs a network request and returns the raw response.
    ///
    /// - Parameter config: The request configuration.
    /// - Returns: A `NetworkResponse` containing the raw data and HTTP metadata.
    /// - Throws: `NetworkError` for transport-level failures.
    public func request(for config: RequestConfiguration) async throws -> NetworkResponse {
        try await withRetry(config.retryCount, delay: config.retryDelay) {
            try await self.performRequest(request: config.urlRequest)
        }
    }

    /// Downloads a file from the network to a specified destination.
    ///
    /// - Parameters:
    ///   - config: The request configuration for the download.
    ///   - destination: The local URL where the file should be saved.
    /// - Returns: The destination URL after a successful download.
    /// - Throws: `NetworkError` for network failures or file system errors.
    public func downloadFile(_ config: RequestConfiguration, to destination: URL) async throws -> URL {
        let urlRequest = config.urlRequest

        return try await withRetry(config.retryCount, delay: config.retryDelay) {
            let (tempURL, response) = try await self.session.download(for: urlRequest, delegate: nil)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }

            try self.validateResponse(httpResponse, data: nil)
            try FileManager.default.moveItem(at: tempURL, to: destination)

            return destination
        }
    }

    /// Uploads a file to the network.
    ///
    /// - Parameters:
    ///   - config: The request configuration for the upload.
    ///   - fileURL: The local file URL to upload.
    /// - Returns: A `NetworkResponse` containing the server's response.
    /// - Throws: `NetworkError` for network failures or file system errors.
    public func uploadFile(_ config: RequestConfiguration, from fileURL: URL) async throws -> NetworkResponse {
        let urlRequest = config.urlRequest

        return try await withRetry(config.retryCount, delay: config.retryDelay) {
            let (data, response) = try await self.session.upload(for: urlRequest, fromFile: fileURL)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }

            try self.validateResponse(httpResponse, data: data)

            return NetworkResponse(data: data, response: httpResponse)
        }
    }

    // MARK: - Private Methods

    private func performRequest(request: URLRequest) async throws -> NetworkResponse {
        var interceptedRequest: URLRequest
        do {
            interceptedRequest = try await interceptorChain.interceptRequest(request)
        } catch InterceptorError.cached(let cachedData) {
            return NetworkResponse(
                data: cachedData,
                response: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            )
        }

        let (data, response) = try await session.data(for: interceptedRequest, delegate: nil)

        let responseData = try await interceptorChain.interceptResponse(response, data: data)

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
            return
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

        for attempt in 1...maxRetries {
            if attempt > 1 {
                logger.log("Retrying network request... Attempt \(attempt) of \(maxRetries)")
            }
            do {
                return try await operation()
            } catch {
                lastError = error

                if shouldNotRetry(error: error) || attempt == maxRetries {
                    throw error
                }

                let retryDelay = delay * Double(attempt)
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }

        throw lastError ?? NetworkError.unknown(URLError(.unknown))
    }

    private func shouldNotRetry(error: Error) -> Bool {
        switch error {
        case
            NetworkError.forbidden,
            NetworkError.notFound,
            NetworkError.decodingError,
            NetworkError.unauthorized,
            InterceptorError.cancelled,
            URLError.badURL,
            URLError.unsupportedURL,
            URLError.cancelled:
            return true
        case let NetworkError.httpError(statusCode, _):
            return statusCode >= 400 && statusCode < 500
        default:
            return false
        }
    }
}
