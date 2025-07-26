//
//  URLSessionProtocol.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/14/25.
//
import Foundation

protocol URLSessionProtocol: Sendable {
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse)
    func upload(for: URLRequest, fromFile: URL) async throws -> (Data, URLResponse)
    func download(for: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse)
}

extension URLSession: URLSessionProtocol {
    static var `default`: URLSessionProtocol {
        Self.shared
    }
}
