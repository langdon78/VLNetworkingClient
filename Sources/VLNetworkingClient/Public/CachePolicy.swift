//
//  CachePolicy.swift
//  HttpClient
//
//  Created by James Langdon on 7/26/25.
//

import Foundation

public enum CachePolicy: Sendable {
    case noCache
    case cacheForMinutes(Int)
    case cacheForHours(Int)
}
