//
//  StringDecoder.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

public final class StringDecoder: ResponseBodyDecoder {
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        if let decoded = String(data: data, encoding: .utf8) as? T {
            return decoded
        }
        throw NetworkError.noData
    }
    
    public init() {}
}
