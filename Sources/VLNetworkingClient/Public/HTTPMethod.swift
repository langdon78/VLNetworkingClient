//
//  HTTPMethod.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

// MARK: - HTTP Method
enum HTTPMethod: String, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

extension HTTPMethod: CustomStringConvertible {
    var description: String {
        rawValue
    }
}
