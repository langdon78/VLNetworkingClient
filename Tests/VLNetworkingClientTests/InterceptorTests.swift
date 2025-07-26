//
//  InterceptorTests.swift
//  HttpClient
//
//  Created by James Langdon on 7/26/25.
//

import Testing
@testable import VLNetworkingClient
import Foundation

@Suite("Authentication Interceptor Tests")
struct AuthenticationInterceptorTests {
    @Test("Add token to header")
    func addTokenToHeader() async throws {
        let mockTokenManager = MockTokenManager(
            accessToken: "mock-access-token",
            expiresAt: Date(timeIntervalSince1970: 1000)
        )
        let authInterceptor = AuthenticationInterceptor(tokenManager: mockTokenManager)
        let originalRequest = URLRequest(url: URL(string: "https://example.com")!)
        let interceptedRequest = try await authInterceptor.intercept(originalRequest)
        
        #expect(interceptedRequest.value(forHTTPHeaderField: "Authorization") == "Bearer mock-token")
    }
    
    @Test("Success")
    func success() async throws {
        let mockTokenManager = MockTokenManager(
            accessToken: "mock-access-token",
            expiresAt: Date(timeIntervalSince1970: 1000)
        )
        let authInterceptor = AuthenticationInterceptor(tokenManager: mockTokenManager)
        let originalResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = "mock-data".data(using: .utf8)!
        let dataAfterRefresh = try await authInterceptor.intercept(originalResponse, data: data)
        
        #expect(data == dataAfterRefresh)
    }
    
    @Test("Should Refresh Token and Retry")
    func authenticationSuccessWithRefresh() async throws {
        let mockTokenManager = MockTokenManager(
            accessToken: "mock-access-token",
            expiresAt: Date(timeIntervalSince1970: 1000)
        )
        let authInterceptor = AuthenticationInterceptor(tokenManager: mockTokenManager)
        let originalResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = "mock-data".data(using: .utf8)!

        await #expect(throws: RequestInterceptorError.shouldRetryRequest) {
            try await authInterceptor.intercept(originalResponse, data: data)
        }
    }
    
    @Test("Failure - Missing Refresh Token")
    func failureMissingRefreshToken() async throws {
        let mockBadTokenManager = MockBadTokenManager()
        let authInterceptor = AuthenticationInterceptor(tokenManager: mockBadTokenManager)
        let originalResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        await #expect(throws: URLError(.userAuthenticationRequired)) {
            try await authInterceptor.intercept(originalResponse, data: nil)
        }
    }
    
    @Test("Failure - Missing Access Token")
    func failureMissingAccessToken() async throws {
        let mockBadTokenManager = MockBadTokenManager()
        let authInterceptor = AuthenticationInterceptor(tokenManager: mockBadTokenManager)
        let originalRequest = URLRequest(url: URL(string: "https://example.com")!)
        let interceptedRequest = try await authInterceptor.intercept(originalRequest)
        
        #expect(interceptedRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }
}

@Suite("Cache Interceptor Tests")
struct CacheInterceptorTests {
    
    @Test("GET request returns cached data when within cache policy")
    func getRequestReturnsCachedData() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(5))
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        let mockData = "cached-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        
        await #expect(throws: RequestInterceptorError.cached(mockData)) {
            try await cacheInterceptor.intercept(request)
        }
    }
    
    @Test("POST request bypasses cache")
    func postRequestBypassesCache() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(5))
        let url = URL(string: "https://example.com/api/data")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let mockData = "cached-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        
        let interceptedRequest = try await cacheInterceptor.intercept(request)
        #expect(interceptedRequest == request)
    }
    
    @Test("Cache expires after policy time limit")
    func cacheExpiresAfterTimeLimit() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(0))
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        let mockData = "cached-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let interceptedRequest = try await cacheInterceptor.intercept(request)
        #expect(interceptedRequest == request)
    }
    
    @Test("No cache policy prevents caching")
    func noCachePolicyPreventsCaching() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .noCache)
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        let mockData = "cached-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        
        let interceptedRequest = try await cacheInterceptor.intercept(request)
        #expect(interceptedRequest == request)
    }
    
    @Test("Only successful responses are cached")
    func onlySuccessfulResponsesAreCached() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(5))
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        let mockData = "error-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        
        let interceptedRequest = try await cacheInterceptor.intercept(request)
        #expect(interceptedRequest == request)
    }
    
    @Test("Response intercept returns original data")
    func responseInterceptReturnsOriginalData() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(5))
        let url = URL(string: "https://example.com/api/data")!
        let mockData = "response-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let returnedData = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        #expect(returnedData == mockData)
    }
    
    @Test("Cache policy hours works correctly")
    func cachePolicyHoursWorksCorrectly() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForHours(1))
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        let mockData = "cached-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        _ = try await cacheInterceptor.intercept(httpResponse, data: mockData)
        
        await #expect(throws: RequestInterceptorError.cached(mockData)) {
            try await cacheInterceptor.intercept(request)
        }
    }
    
    @Test("Request without URL returns same request")
    func requestWithoutURLReturnsSameRequest() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(5))
        let request = URLRequest(url: URL(string: "about:blank")!)
        
        let interceptedRequest = try await cacheInterceptor.intercept(request)
        #expect(interceptedRequest == request)
    }
    
    @Test("Response without data does not crash")
    func responseWithoutDataDoesNotCrash() async throws {
        let cacheInterceptor = CacheInterceptor(cachePolicy: .cacheForMinutes(5))
        let url = URL(string: "https://example.com/api/data")!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let returnedData = try await cacheInterceptor.intercept(httpResponse, data: nil)
        #expect(returnedData == nil)
    }
}

@Suite("Rate Limit Interceptor Tests")
struct RateLimitInterceptorTests {
    
    @Test("Request returns unchanged when under rate limit")
    func requestReturnsUnchangedWhenUnderRateLimit() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 60)
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        
        let interceptedRequest = try await rateLimitInterceptor.intercept(request)
        #expect(interceptedRequest == request)
    }
    
    @Test("Response returns original data")
    func responseReturnsOriginalData() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 60)
        let url = URL(string: "https://example.com/api/data")!
        let mockData = "response-data".data(using: .utf8)!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let returnedData = try await rateLimitInterceptor.intercept(httpResponse, data: mockData)
        #expect(returnedData == mockData)
    }
    
    @Test("Response returns nil when data is nil")
    func responseReturnsNilWhenDataIsNil() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 60)
        let url = URL(string: "https://example.com/api/data")!
        
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let returnedData = try await rateLimitInterceptor.intercept(httpResponse, data: nil)
        #expect(returnedData == nil)
    }
    
    @Test("Multiple requests under limit succeed quickly")
    func multipleRequestsUnderLimitSucceedQuickly() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 10)
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        
        let startTime = Date()
        
        for _ in 0..<5 {
            _ = try await rateLimitInterceptor.intercept(request)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1)
    }
    
    @Test("Rate limit enforces delay when limit exceeded")
    func rateLimitEnforcesDelayWhenLimitExceeded() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 2)
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        
        _ = try await rateLimitInterceptor.intercept(request)
        _ = try await rateLimitInterceptor.intercept(request)
        
        let startTime = Date()
        _ = try await rateLimitInterceptor.intercept(request)
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(elapsed >= 59.0)
    }
    
    @Test("Rate limit clears old requests after time window")
    func rateLimitClearsOldRequestsAfterTimeWindow() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 1)
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        
        _ = try await rateLimitInterceptor.intercept(request)
        
        try await Task.sleep(nanoseconds: 61_000_000_000)
        
        let startTime = Date()
        _ = try await rateLimitInterceptor.intercept(request)
        let elapsed = Date().timeIntervalSince(startTime)
        
        #expect(elapsed < 1.0)
    }
    
    @Test("Custom max requests per minute works correctly")
    func customMaxRequestsPerMinuteWorksCorrectly() async throws {
        let rateLimitInterceptor = RateLimitInterceptor(maxRequestsPerMinute: 3)
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        
        let startTime = Date()
        
        for _ in 0..<3 {
            _ = try await rateLimitInterceptor.intercept(request)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 0.1)
    }
    
    @Test("Default rate limit is 60 requests per minute")
    func defaultRateLimitIs60RequestsPerMinute() async throws {
        let rateLimitInterceptor = RateLimitInterceptor()
        let url = URL(string: "https://example.com/api/data")!
        let request = URLRequest(url: url)
        
        let startTime = Date()
        
        for _ in 0..<60 {
            _ = try await rateLimitInterceptor.intercept(request)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        #expect(elapsed < 1.0)
    }
}
