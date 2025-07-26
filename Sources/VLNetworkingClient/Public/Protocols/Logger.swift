//
//  Logger.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

public protocol Logger: Actor {
    func log(_ message: String)
    func debug(_ message: String)
}
