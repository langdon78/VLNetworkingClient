//
//  RequestBodyEncoder.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

public protocol RequestBodyEncoder: Sendable {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

extension JSONEncoder: RequestBodyEncoder {}
