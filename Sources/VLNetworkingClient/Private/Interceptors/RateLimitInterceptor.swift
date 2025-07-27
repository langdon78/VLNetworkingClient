//
//  RateLimitInterceptor.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

actor RateLimitInterceptor: Interceptor {
    private let maxRequestsPerMinute: Int
    private var requestTimes: [Date] = []
    
    init(maxRequestsPerMinute: Int = 60) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        try await enforceRateLimit()
        return request
    }
    
    func intercept(_ response: URLResponse, data: Data?) async throws -> Data? {
        return data
    }
    
    private func enforceRateLimit() async throws {
        
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // Remove old requests
        requestTimes.removeAll(where: { time in
            return time < oneMinuteAgo
        })
        
        // Check if we're at the limit
        if requestTimes.count >= maxRequestsPerMinute {
            if let oldestRequest = requestTimes.first {
                let waitTime = 60 - now.timeIntervalSince(oldestRequest)
                if waitTime > 0 {
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                }
            }
        }
        
        // Add current request
        requestTimes.append(now)
    }
}
