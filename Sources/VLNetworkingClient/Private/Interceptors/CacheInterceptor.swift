//
//  CachedInterceptor.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

final actor CacheInterceptor: Interceptor {
    private let cache = NSCache<NSString, CachedResponse>()
    private let cachePolicy: CachePolicy
    
    init(cachePolicy: CachePolicy = .cacheForMinutes(5)) {
        self.cachePolicy = cachePolicy
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // Check cache for GET requests
        if request.httpMethod == "GET" || request.httpMethod == nil {
            if let cachedResponse = getCachedResponse(for: request) {
                // Return cached data by throwing a special error that includes the cached response
                throw InterceptorError.cached(cachedResponse.data)
            }
        }
        
        return request
    }
    
    func intercept(_ response: URLResponse, data: Data?) async throws -> Data? {
        // Cache successful GET responses
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 200,
           let data = data,
           let url = response.url {
            
            let cachedResponse = CachedResponse(
                data: data,
                timestamp: Date(),
                url: url
            )
            
            cache.setObject(cachedResponse, forKey: url.absoluteString as NSString)
        }
        
        return data
    }
    
    private func getCachedResponse(for request: URLRequest) -> CachedResponse? {
        guard let url = request.url else { return nil }
        
        if let cached = cache.object(forKey: url.absoluteString as NSString) {
            let cacheAge = Date().timeIntervalSince(cached.timestamp)
            
            let maxAge: TimeInterval = switch cachePolicy {
            case .noCache:
                0
            case .cacheForMinutes(let minutes):
                TimeInterval(minutes * 60)
            case .cacheForHours(let hours):
                TimeInterval(hours * 3600)
            }
            
            if cacheAge <= maxAge {
                return cached
            } else {
                cache.removeObject(forKey: url.absoluteString as NSString)
            }
        }
        
        return nil
    }
}
