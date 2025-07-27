//
//  TokenManager.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

public protocol TokenManager: Actor {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var expiresAt: Date? { get }
    
    func getValidToken() async -> String?
    func refreshToken() async throws
}

extension TokenManager {
    public var isAuthenticated: Bool {
        return accessToken != nil
    }
}
