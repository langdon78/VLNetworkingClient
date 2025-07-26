//
//  AuthenticationInterceptor.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

final class AuthenticationInterceptor: RequestInterceptor {
    
    private let tokenManager: TokenManager
    
    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        
        // Add authorization header to every request
        if let token = await tokenManager.getValidToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return modifiedRequest
    }
    
    func intercept(_ response: URLResponse, data: Data?) async throws -> Data? {
        // Handle 401 responses by refreshing token
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            try await tokenManager.refreshToken()
            // Could throw a custom error to trigger request retry
            throw RequestInterceptorError.shouldRetryRequest
        }
        return data
    }
}
