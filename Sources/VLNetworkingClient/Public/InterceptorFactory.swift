//
//  InterceptorFactory.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation
import VLDebugLogger

public struct InterceptorFactory {
    public static func make(
        configuration: IntercepterConfiguration
    ) -> any Interceptor {
        switch configuration {
        case .authentication(tokenManager: let tokenManager):
            return AuthenticationInterceptor(tokenManager: tokenManager)
        case .logging(logger: let logger):
            return LoggingInterceptor(logger: logger)
        case .rateLimit(maxRequestsPerMinute: let maxRequestsPerMinute):
            return RateLimitInterceptor(maxRequestsPerMinute: maxRequestsPerMinute)
        case .cache(cachePolicy: let cachePolicy):
            return CacheInterceptor(cachePolicy: cachePolicy)
        }
    }
    
    public enum IntercepterConfiguration {
        case authentication(tokenManager: TokenManager)
        case logging(logger: VLDebugLogger = VLDebugLogger.shared)
        case rateLimit(maxRequestsPerMinute: Int)
        case cache(cachePolicy: CachePolicy)
    }
}
