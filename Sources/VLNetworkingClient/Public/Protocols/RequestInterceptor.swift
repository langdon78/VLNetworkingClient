//
//  RequestInterceptor.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/14/25.
//

import Foundation

// MARK: - RequestInterceptor Protocol
public protocol RequestInterceptor: Sendable {
    /// Called before a request is sent
    func intercept(_ request: URLRequest) async throws -> URLRequest
    
    /// Called after a response is received (optional)
    func intercept(_ response: URLResponse, data: Data?) async throws -> Data?
}

public enum RequestInterceptorError: Error {
    case cancelled
    case cached(Data)
    case shouldRetryRequest
}

extension RequestInterceptorError: Equatable {}
