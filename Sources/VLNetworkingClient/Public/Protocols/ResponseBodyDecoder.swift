//
//  Decoder.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/14/25.
//
import Foundation
import Combine

public protocol ResponseBodyDecoder: Sendable {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

extension JSONDecoder: ResponseBodyDecoder {}
