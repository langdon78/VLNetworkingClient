//
//  MockUsers.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Foundation

// MARK: - Sample Models for Testing
struct User: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
    let createdAt: Date
}

extension User {
    static var mock: User {
        .init(
            id: 1,
            name: "John Doe",
            email: "john@example.com",
            createdAt: mockDate
        )
    }
    
    static var mockDate: Date {
        var components = DateComponents()
        components.year = 2023
        components.month = 12
        components.day = 1
        components.hour = 10
        components.minute = 0
        components.second = 0
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: components)!
    }
}


// MARK: - Test Models
struct TestUser: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    let email: String
}

struct TestError: Codable {
    let message: String
    let code: Int
}
