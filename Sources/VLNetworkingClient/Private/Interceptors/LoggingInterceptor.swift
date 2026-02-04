//
//  LoggingInterceptor.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation
import VLDebugLogger

final actor LoggingInterceptor: Interceptor {
    private let logger: VLDebugLogger
    
    init(logger: VLDebugLogger = VLDebugLogger.shared) {
        self.logger = logger
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        logger.log(request)
        return request
    }
    
    func intercept(_ response: URLResponse, data: Data?) async throws -> Data? {
        logger.log(response, data: data, showData: false)
        return data
    }
}
