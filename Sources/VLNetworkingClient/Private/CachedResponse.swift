//
//  CachedResponse.swift
//  DiscogsAPIClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

final class CachedResponse: Sendable {
    let data: Data
    let timestamp: Date
    let url: URL
    
    init(data: Data, timestamp: Date, url: URL) {
        self.data = data
        self.timestamp = timestamp
        self.url = url
    }
}
