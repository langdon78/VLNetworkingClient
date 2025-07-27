//
//  Collection.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/26/25.
//

import Foundation

extension Collection {
    func asyncReduce<Result>(initialResult: Result, _ combine: @escaping (Result, Element) async throws -> Result) async rethrows -> Result {
        var result = initialResult
        for element in self {
            result = try await combine(result, element)
        }
        return result
    }
}
