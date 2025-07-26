//
//  InterceptorChain.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/14/25.
//

import Foundation

// MARK: - Interceptor Chain Manager
final actor InterceptorChain: InterceptorChainProtocol {
    private var interceptors: [RequestInterceptor]
    
    init(interceptors: [RequestInterceptor] = []) {
        self.interceptors = interceptors
    }
    
    func add(_ interceptor: RequestInterceptor) async {
        interceptors.append(interceptor)
    }
    
    func interceptRequest(_ request: URLRequest) async throws -> URLRequest {
        try await interceptors.asyncReduce(initialResult: request) { result, interceptor in
            try await interceptor.intercept(result)
        }
    }
    
    func interceptResponse(_ response: URLResponse, data: Data?) async throws -> Data? {
        try await interceptors.asyncReduce(initialResult: data) { result, interceptor in
            try await interceptor.intercept(response, data: result)
        }
    }
}
