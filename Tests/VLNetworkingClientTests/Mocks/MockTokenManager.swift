//
//  MockTokenManager.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation
@testable import VLNetworkingClient

actor MockTokenManager: TokenManager {
    var accessToken: String?
    var refreshToken: String?
    var expiresAt: Date?
    
    init(accessToken: String? = nil, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
    
    func getValidToken() async -> String? {
        "mock-token"
    }
    
    func refreshToken() async throws {
        refreshToken = "mock-refresh-token"
    }
}

actor MockBadTokenManager: TokenManager {
    var accessToken: String?
    var refreshToken: String?
    var expiresAt: Date?
    
    init(accessToken: String? = nil, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
    
    func getValidToken() async -> String? {
        nil
    }
    
    func refreshToken() async throws {
        throw URLError(.userAuthenticationRequired)
    }
}
