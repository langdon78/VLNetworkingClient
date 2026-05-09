//
//  URLSessionProtocol.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/14/25.
//
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol URLSessionProtocol: Sendable {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse)
    func upload(for request: URLRequest, fromFile url: URL) async throws -> (Data, URLResponse)
    func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse)
}

// Default implementation for platforms where upload(for:fromFile:) is not provided
// by URLSession (e.g. Linux/FoundationNetworking). Reads the file into memory and
// delegates to data(for:delegate:).
public extension URLSessionProtocol {
    func upload(for request: URLRequest, fromFile url: URL) async throws -> (Data, URLResponse) {
        let body = try Data(contentsOf: url)
        var req = request
        req.httpBody = body
        return try await data(for: req, delegate: nil)
    }
}

extension URLSession: URLSessionProtocol {}
