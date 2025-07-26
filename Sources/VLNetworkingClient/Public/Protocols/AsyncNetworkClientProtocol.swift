//
//  NetworkClientProtocol.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

// MARK: - Network Client Protocol

/// Protocol defining the interface for an async network client.
///
/// This protocol defines the core networking operations that any network client implementation should provide.
/// It includes support for basic requests, file downloads, and file uploads with async/await patterns.
public protocol AsyncNetworkClientProtocol: Actor {
    
    /// Performs a network request and decodes the response to the specified type.
    /// - Parameters:
    ///   - config: The request configuration.
    ///   - decoder: The decoder for parsing the response body.
    /// - Returns: A network response containing the decoded data.
    /// - Throws: Network or decoding errors.
    func requestWithDecoder<T: Codable>(
        _ config: RequestConfiguration,
        decoder: ResponseBodyDecoder
    ) async throws -> NetworkResponse<T>
    
    /// Performs a network request and returns raw response data.
    /// - Parameter config: The request configuration.
    /// - Returns: A network response containing raw data.
    /// - Throws: Network errors.
    func request(
        _ config: RequestConfiguration
    ) async throws -> NetworkResponse<Data>
    
    /// Downloads a file to the specified destination.
    /// - Parameters:
    ///   - config: The request configuration.
    ///   - destination: The local destination URL.
    /// - Returns: A network response containing the destination URL.
    /// - Throws: Network or file system errors.
    func downloadFile(
        _ config: RequestConfiguration,
        to destination: URL
    ) async throws -> NetworkResponse<URL>
    
    /// Uploads a file from the specified location.
    /// - Parameters:
    ///   - config: The request configuration.
    ///   - fileURL: The local file URL to upload.
    /// - Returns: A network response containing the server response data.
    /// - Throws: Network or file system errors.
    func uploadFile(
        _ config: RequestConfiguration,
        from fileURL: URL
    ) async throws -> NetworkResponse<Data>
}
