//
//  NetworkErrorTests.swift
//  VLNetworkingClient
//

import Testing
@testable import VLNetworkingClient
import Foundation

/// `DecodingError.localizedDescription` bridges to Foundation's generic,
/// case-agnostic NSError text (e.g. "The data couldn't be read because it
/// is missing.") regardless of which field actually failed — useless for
/// diagnosing a real decoding failure after the fact. `NetworkError
/// .errorDescription`'s `.decodingError` case now formats the wrapped
/// `DecodingError`'s own `codingPath`/`debugDescription` instead of
/// discarding them.
@Suite("NetworkError decoding-error description")
struct NetworkErrorTests {
    private struct Fixture: Codable {
        let id: Int
        let name: String
    }

    private let decoder = JSONDecoder()

    private func decode(_ json: String) -> DecodingError {
        decode(json, as: Fixture.self)
    }

    private func decode<T: Decodable>(_ json: String, as type: T.Type) -> DecodingError {
        let data = json.data(using: .utf8)!
        do {
            _ = try decoder.decode(type, from: data)
            Issue.record("Expected decode to throw")
            return .dataCorrupted(.init(codingPath: [], debugDescription: "unreachable"))
        } catch let error as DecodingError {
            return error
        } catch {
            Issue.record("Expected a DecodingError, got \(error)")
            return .dataCorrupted(.init(codingPath: [], debugDescription: "unreachable"))
        }
    }

    @Test("Null value for a non-optional field names the failing key")
    func nullValueNamesTheFailingKey() {
        let error = decode(#"{"id": 1, "name": null}"#)
        let description = NetworkError.decodingError(error).errorDescription ?? ""
        #expect(description.contains("name"))
        #expect(description.contains("null value"))
    }

    @Test("Missing key names the failing key")
    func missingKeyNamesTheFailingKey() {
        let error = decode(#"{"id": 1}"#)
        let description = NetworkError.decodingError(error).errorDescription ?? ""
        #expect(description.contains("missing key 'name'"))
    }

    @Test("Type mismatch names the failing key and coding path")
    func typeMismatchNamesTheFailingKey() {
        let error = decode(#"{"id": "not a number", "name": "Test"}"#)
        let description = NetworkError.decodingError(error).errorDescription ?? ""
        #expect(description.contains("id"))
        #expect(description.contains("type mismatch"))
    }

    @Test("Nested coding path is dot-joined, including array indices")
    func nestedCodingPathIsDotJoined() {
        struct Wrapper: Codable {
            let items: [Fixture]
        }
        let json = #"{"items": [{"id": 1, "name": "A"}, {"id": 2, "name": null}]}"#
        let error = decode(json, as: Wrapper.self)
        let description = NetworkError.decodingError(error).errorDescription ?? ""
        #expect(description.contains("items.1.name"))
    }

    @Test("A non-DecodingError wrapped value falls back to its own localizedDescription")
    func nonDecodingErrorFallsBackToLocalizedDescription() {
        struct PlainError: LocalizedError {
            var errorDescription: String? { "plain failure" }
        }
        let description = NetworkError.decodingError(PlainError()).errorDescription
        #expect(description == "Decoding error: plain failure")
    }
}
