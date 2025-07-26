//
//  InterceptorChainProtocol.swift
//  HttpClient
//
//  Created by James Langdon on 7/26/25.
//

import Foundation

public protocol InterceptorChainProtocol: Actor {
    func add(_ interceptor: RequestInterceptor) async
    func interceptRequest(_ request: URLRequest) async throws -> URLRequest
    func interceptResponse(_ response: URLResponse, data: Data?) async throws -> Data?
}
