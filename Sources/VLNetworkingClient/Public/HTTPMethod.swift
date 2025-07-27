//
//  HTTPMethod.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

// MARK: - HTTP Method
public enum HTTPMethod: String, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

extension HTTPMethod: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
