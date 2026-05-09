//
//  NetworkClientProtocol.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Network Client Protocol

/// Protocol defining the interface for an async network client.
///
/// The client is responsible for transport: making HTTP requests, running interceptors,
/// and returning raw `NetworkResponse` values. Callers decode the response body using
/// `NetworkResponse.decode(_:using:)`.
public protocol AsyncNetworkClientProtocol: Actor {

    /// Performs a network request and returns the raw response.
    /// - Parameter config: The request configuration.
    /// - Returns: A `NetworkResponse` containing the raw data and HTTP metadata.
    /// - Throws: `NetworkError` for transport-level failures.
    func request(for config: RequestConfiguration) async throws -> NetworkResponse

    /// Downloads a file to the specified destination.
    /// - Parameters:
    ///   - config: The request configuration.
    ///   - destination: The local URL where the file should be saved.
    /// - Returns: The destination URL after a successful download.
    /// - Throws: `NetworkError` for network or file system failures.
    func downloadFile(
        _ config: RequestConfiguration,
        to destination: URL
    ) async throws -> URL

    /// Uploads a file from the specified location.
    /// - Parameters:
    ///   - config: The request configuration.
    ///   - fileURL: The local file URL to upload.
    /// - Returns: A `NetworkResponse` containing the server's response.
    /// - Throws: `NetworkError` for network or file system failures.
    func uploadFile(
        _ config: RequestConfiguration,
        from fileURL: URL
    ) async throws -> NetworkResponse
}
