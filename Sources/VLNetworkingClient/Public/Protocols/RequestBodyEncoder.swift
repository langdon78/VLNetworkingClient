//
//  RequestBodyEncoder.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol RequestBodyEncoder: Sendable {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
}

extension JSONEncoder: RequestBodyEncoder {}
