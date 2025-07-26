//
//  APIErrorMock.swift
//  HttpClient
//
//  Created by James Langdon on 7/15/25.
//

import Foundation

// MARK: - Mock Data Generator
class MockDataGenerator {
    
    // MARK: - Valid JSON Data
    static func validUserJSON() -> Data {
        let jsonString = """
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "createdAt": "2023-12-01T10:00:00Z"
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    // MARK: - Invalid JSON Data (Various Error Types)
    
    /// Missing required field
    static func missingFieldJSON() -> Data {
        let jsonString = """
        {
            "id": 1,
            "name": "John Doe"
            // Missing email and createdAt
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    /// Wrong data type
    static func wrongDataTypeJSON() -> Data {
        let jsonString = """
        {
            "id": "not_a_number",
            "name": "John Doe",
            "email": "john@example.com",
            "createdAt": "2023-12-01T10:00:00Z"
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    /// Invalid date format
    static func invalidDateFormatJSON() -> Data {
        let jsonString = """
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "createdAt": "invalid-date"
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    /// Malformed JSON
    static func malformedJSON() -> Data {
        let jsonString = """
        {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com"
            // Missing closing brace and comma
        """
        return jsonString.data(using: .utf8)!
    }
    
    /// Null values where not expected
    static func nullValuesJSON() -> Data {
        let jsonString = """
        {
            "id": 1,
            "name": null,
            "email": "john@example.com",
            "createdAt": "2023-12-01T10:00:00Z"
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    /// Empty JSON
    static func emptyJSON() -> Data {
        return "{}".data(using: .utf8)!
    }
    
    /// Array instead of object
    static func arrayInsteadOfObjectJSON() -> Data {
        let jsonString = """
        [
            {
                "id": 1,
                "name": "John Doe",
                "email": "john@example.com",
                "createdAt": "2023-12-01T10:00:00Z"
            }
        ]
        """
        return jsonString.data(using: .utf8)!
    }
}
