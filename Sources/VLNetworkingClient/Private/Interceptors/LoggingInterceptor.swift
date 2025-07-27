//
//  LoggingInterceptor.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

final actor LoggingInterceptor: Interceptor {
    private let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        await logger.debug("🌐 REQUEST: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        
        // Log headers (excluding sensitive ones)
        if let headers = request.allHTTPHeaderFields {
            let safeHeaders = headers.filter { key, _ in
                !["Authorization", "X-API-Key"].contains(key)
            }
            await logger.debug("📋 Headers: \(safeHeaders)")
        }
        
        // Log body for POST/PUT requests
        if let body = request.httpBody {
            await logger.debug("📝 Body: \(String(data: body, encoding: .utf8) ?? "Binary data")")
        }
        
        return request
    }
    
    func intercept(_ response: URLResponse, data: Data?) async throws -> Data? {
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = httpResponse.statusCode < 400 ? "✅" : "❌"
            await logger.debug("\(statusEmoji) RESPONSE: \(httpResponse.statusCode) for \(httpResponse.url?.absoluteString ?? "")")
        }
        
        if let data = data {
            await logger.debug("📦 Response size: \(data.count) bytes")
        }
        
        return data
    }
}
