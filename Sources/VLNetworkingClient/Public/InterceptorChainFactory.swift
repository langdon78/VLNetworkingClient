//
//  InterceptorChainFactory.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

public struct InterceptorChainFactory {
    public static func make(
        configuration: IntercepterChainConfiguration
    ) -> any RequestInterceptor {
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
    
    public enum IntercepterChainConfiguration {
        case authentication(tokenManager: TokenManager)
        case logging(logger: Logger)
        case rateLimit(maxRequestsPerMinute: Int)
        case cache(cachePolicy: CachePolicy)
    }
}
