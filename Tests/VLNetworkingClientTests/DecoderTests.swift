//
//  DecoderTests.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Testing
@testable import VLNetworkingClient
import Foundation

@Suite("JSON Decoding Tests")
struct DecodingTests {
    let mockUser = User.mock
    let decoder = JSONDecoder()
    
    init() {
        decoder.dateDecodingStrategy = .iso8601
    }

    @Test("Valid", arguments:
        [
            ("Valid", MockDataGenerator.validUserJSON())
        ]
    )
    func decodeValidJson(json: (String, data: Data?)) async throws {
        let result: User = try decoder.decode(User.self, from: json.data!)
        #expect(
            result == mockUser
        )
    }
    
    @Test("Invalid", arguments:
        [
            ("Empty", MockDataGenerator.emptyJSON()),
            ("Missing field", MockDataGenerator.missingFieldJSON()),
            ("Invalid date format", MockDataGenerator.invalidDateFormatJSON()),
            ("Array instead of object", MockDataGenerator.arrayInsteadOfObjectJSON()),
            ("Null value json", MockDataGenerator.nullValuesJSON()),
            ("Wrong data type", MockDataGenerator.wrongDataTypeJSON())
        ]
    )
    func decodeInvalidJson(json: (String, data: Data?)) async throws {
        #expect(throws: DecodingError.self) {
            try decoder.decode(User.self, from: json.data!)
        }
    }
}

@Suite("String Decoding Tests")
struct StringDecodingTests {
    let mockString = "Hello World"
    let mockData = "Hello World".data(using: .utf8)!
    let mockBadData = Data()
    let decoder = StringDecoder()

    @Test("Valid")
    func decodeValidString() async throws {
        let result: String = try decoder.decode(String.self, from: mockData)
        #expect(
            result == mockString
        )
    }
    
    @Test("Invalid")
    func decodeInvalidString() async throws {
        let result: String = try decoder.decode(String.self, from: mockBadData)
        #expect(result == "")
    }
}
