//
//  Logger.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

public protocol Logger: Sendable {
    func log(_ message: String)
    func debug(_ message: String)
}

extension Logger {
    public func log(_ message: String) {
        print("LOG \(message)")
    }
    
    public func debug(_ message: String) {
        print("DEBUG \(message)")
    }
}

public final class DefaultLogger: Logger {
    public init() {}
}
