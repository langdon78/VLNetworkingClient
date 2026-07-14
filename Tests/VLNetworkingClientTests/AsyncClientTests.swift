//
//  AsyncClientTests.swift
//  VLNetworkingClient
//
//  Created by James Langdon on 7/16/25.
//

import Testing
@testable import VLNetworkingClient
import Foundation

// MARK: - Test Helper Functions
func createMockHTTPResponse(statusCode: Int = 200, url: URL? = nil, headers: [String: String]? = nil) -> HTTPURLResponse {
    let responseURL = url ?? URL(string: "https://api.example.com/test")!
    return HTTPURLResponse(
        url: responseURL,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: headers ?? ["Content-Type": "application/json"]
    )!
}

func createTestUser() -> TestUser {
    return TestUser(id: 1, name: "John Doe", email: "john@example.com")
}

// MARK: - Network Client Tests
@Suite("Network Client Tests")
struct NetworkClientTests {

    @Test("Successful GET request with JSON response")
    func testSuccessfulGetRequest() async throws {
        // Arrange
        let testUser = createTestUser()
        let jsonData = try JSONEncoder().encode(testUser)

        let mockSession = MockURLSession(
            mockData: jsonData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!

        // Act
        let response = try await client.request(for: RequestConfiguration(url: testURL, method: .GET))

        // Assert
        #expect(try response.decode(TestUser.self) == testUser)
        #expect(response.statusCode == 200)
        await #expect(mockSession.requestCount == 1)
        await #expect(mockSession.lastRequest?.httpMethod == "GET")
        await #expect(mockSession.lastRequest?.url == testURL)
    }

    @Test("Successful POST request with JSON body")
    func testSuccessfulPostRequest() async throws {
        // Arrange
        let inputUser = TestUser(id: 0, name: "Jane Doe", email: "jane@example.com")
        let responseUser = TestUser(id: 1, name: "Jane Doe", email: "jane@example.com")

        let responseData = try JSONEncoder().encode(responseUser)

        let mockSession = MockURLSession(
            mockData: responseData,
            mockResponse: createMockHTTPResponse(statusCode: 201)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users")!
        let config = try RequestConfiguration(url: testURL, method: .POST).withEncodableBody(inputUser)

        // Act
        let response = try await client.request(for: config)

        // Assert
        #expect(try response.decode(TestUser.self) == responseUser)
        #expect(response.statusCode == 201)
        await #expect(mockSession.requestCount == 1)
        await #expect(mockSession.lastRequest?.httpMethod == "POST")

        // Verify request body
        let sentData = await mockSession.lastRequest?.httpBody
        let sentUser = try JSONDecoder().decode(TestUser.self, from: sentData!)
        #expect(sentUser == inputUser)
    }

    @Test("HTTP 404 error handling")
    func testNotFoundError() async throws {
        // Arrange
        let mockSession = MockURLSession(
            mockData: Data(),
            mockResponse: createMockHTTPResponse(statusCode: 404)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/999")!

        // Act & Assert
        await #expect(throws: NetworkError.notFound) {
            _ = try await client.request(for: RequestConfiguration(url: testURL, method: .GET))
        }
    }

    @Test("HTTP 401 unauthorized error handling")
    func testUnauthorizedError() async throws {
        // Arrange
        let mockSession = MockURLSession(
            mockData: Data(),
            mockResponse: createMockHTTPResponse(statusCode: 401)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users")!

        // Act & Assert
        await #expect(throws: NetworkError.unauthorized) {
            _ = try await client.request(for: RequestConfiguration(url: testURL, method: .GET))
        }
    }

    @Test("HTTP 500 server error handling")
    func testServerError() async throws {
        // Arrange
        let mockSession = MockURLSession(
            mockData: Data(),
            mockResponse: createMockHTTPResponse(statusCode: 500)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users")!

        // Act & Assert
        await #expect(throws: NetworkError.serverUnavailable) {
            _ = try await client.request(for: RequestConfiguration(url: testURL, method: .GET))
        }
    }

    @Test("Custom request configuration")
    func testCustomRequestConfiguration() async throws {
        // Arrange
        let testUser = createTestUser()
        let jsonData = try JSONEncoder().encode(testUser)

        let mockSession = MockURLSession(
            mockData: jsonData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!
        let customHeaders = ["Authorization": "Bearer test-token", "Custom-Header": "test-value"]

        let config = RequestConfiguration(
            url: testURL,
            method: .GET,
            headers: customHeaders,
            timeoutInterval: 60.0
        )

        // Act
        let response = try await client.request(for: config)

        // Assert
        #expect(try response.decode(TestUser.self) == testUser)
        await #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        await #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "Custom-Header") == "test-value")
        await #expect(mockSession.lastRequest?.timeoutInterval == 60.0)
    }

    @Test("Default headers configuration")
    func testDefaultHeaders() async throws {
        // Arrange
        let testUser = createTestUser()
        let jsonData = try JSONEncoder().encode(testUser)

        let mockSession = MockURLSession(
            mockData: jsonData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!
        let customHeaders = [
            "Authorization": "Bearer default-token",
            "User-Agent": "TestApp/1.0"
        ]

        // Act
        let response = try await client.request(for: RequestConfiguration(url: testURL, method: .GET, headers: customHeaders))

        // Assert
        #expect(try response.decode(TestUser.self) == testUser)
        await #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer default-token")
        await #expect(mockSession.lastRequest?.value(forHTTPHeaderField: "User-Agent") == "TestApp/1.0")
    }

    @Test("Raw data request")
    func testRawDataRequest() async throws {
        // Arrange
        let testData = "Hello, World!".data(using: .utf8)!
        let mockSession = MockURLSession(
            mockData: testData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/raw")!
        let config = RequestConfiguration(url: testURL, method: .GET)

        // Act
        let response = try await client.request(for: config)

        // Assert
        #expect(response.data == testData)
        #expect(response.statusCode == 200)
    }

    @Test("File download success")
    func testFileDownloadSuccess() async throws {
        // Arrange
        let testContent = "Test file content for download".data(using: .utf8)!
        let downloadURL = URL(string: "https://api.example.com/files/test.txt")!

        // Create a temporary file that the mock session will return
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("mock_download_\(UUID().uuidString).txt")
        try testContent.write(to: tempFile)

        // Create mock session that returns the temp file URL
        actor DownloadMockSession: URLSessionProtocol, Sendable {
            let tempFileURL: URL
            let mockResponse: URLResponse
            var requestCount = 0
            var lastRequest: URLRequest?

            init(tempFileURL: URL, mockResponse: URLResponse) {
                self.tempFileURL = tempFileURL
                self.mockResponse = mockResponse
            }

            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                requestCount += 1
                lastRequest = request
                return (tempFileURL, mockResponse)
            }
        }

        let mockSession = DownloadMockSession(
            tempFileURL: tempFile,
            mockResponse: createMockHTTPResponse(statusCode: 200, url: downloadURL)
        )
        let client = AsyncNetworkClient(session: mockSession)

        // Create destination file path
        let destinationDir = FileManager.default.temporaryDirectory
        let destination = destinationDir.appendingPathComponent("downloaded_test_\(UUID().uuidString).txt")

        let config = RequestConfiguration(url: downloadURL, method: .GET)

        // Act
        let resultURL = try await client.downloadFile(config, to: destination)

        // Assert
        #expect(resultURL == destination)
        #expect(FileManager.default.fileExists(atPath: destination.path))
        await #expect(mockSession.requestCount == 1)
        await #expect(mockSession.lastRequest?.url == downloadURL)

        // Verify file content was moved correctly
        let downloadedContent = try Data(contentsOf: destination)
        #expect(downloadedContent == testContent)

        // Cleanup
        try? FileManager.default.removeItem(at: destination)
        try? FileManager.default.removeItem(at: tempFile)
    }

    @Test("File download with HTTP error")
    func testFileDownloadHTTPError() async throws {
        // Arrange
        let downloadURL = URL(string: "https://api.example.com/files/notfound.txt")!
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("temp_\(UUID().uuidString).txt")

        actor ErrorDownloadMockSession: URLSessionProtocol, Sendable {
            let tempFileURL: URL
            let mockResponse: URLResponse

            init(tempFileURL: URL, mockResponse: URLResponse) {
                self.tempFileURL = tempFileURL
                self.mockResponse = mockResponse
            }

            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                return (tempFileURL, mockResponse)
            }
        }

        let mockSession = ErrorDownloadMockSession(
            tempFileURL: tempFile,
            mockResponse: createMockHTTPResponse(statusCode: 404, url: downloadURL)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("download_dest_\(UUID().uuidString).txt")
        let config = RequestConfiguration(url: downloadURL, method: .GET)

        // Act & Assert
        await #expect(throws: NetworkError.notFound) {
            _ = try await client.downloadFile(config, to: destination)
        }

        // Cleanup
        try? FileManager.default.removeItem(at: tempFile)
        try? FileManager.default.removeItem(at: destination)
    }

    @Test("File download network error")
    func testFileDownloadNetworkError() async throws {
        // Arrange
        let downloadURL = URL(string: "https://api.example.com/files/test.txt")!

        actor NetworkErrorMockSession: URLSessionProtocol, Sendable {
            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                throw URLError(.networkConnectionLost)
            }
        }

        let mockSession = NetworkErrorMockSession()
        let client = AsyncNetworkClient(session: mockSession)

        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("download_dest_\(UUID().uuidString).txt")
        let config = RequestConfiguration(url: downloadURL, method: .GET)

        // Act & Assert
        await #expect(throws: URLError.self) {
            _ = try await client.downloadFile(config, to: destination)
        }

        // Cleanup
        try? FileManager.default.removeItem(at: destination)
    }

    static func urlForRestServicesTestsDir() -> URL {
        let currentFileURL = URL(fileURLWithPath: "\(#file)", isDirectory: false)
        return currentFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    @Test("File upload")
    func testFileUpload() async throws {
        // Arrange
        let responseData = """
        {
            "message": "File uploaded successfully",
            "id": "12345"
        }
        """.data(using: .utf8)!

        let mockSession = MockURLSession(
            mockData: responseData,
            mockResponse: createMockHTTPResponse(statusCode: 201)
        )
        let client = AsyncNetworkClient(session: mockSession)

        // Create test file
        let testFileContent = "Test file content".data(using: .utf8)!
        let testFileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test_upload.txt")
        try testFileContent.write(to: testFileURL)

        let uploadURL = URL(string: "https://api.example.com/upload")!
        let config = RequestConfiguration(url: uploadURL, method: .POST)

        // Act
        let response = try await client.uploadFile(config, from: testFileURL)

        // Assert
        #expect(response.data == responseData)
        #expect(response.statusCode == 201)
        await #expect(mockSession.requestCount == 1)

        // Cleanup
        try? FileManager.default.removeItem(at: testFileURL)
    }

    @Test("PUT request")
    func testPutRequest() async throws {
        // Arrange
        let updatedUser = TestUser(id: 1, name: "Updated Name", email: "updated@example.com")
        let responseData = try JSONEncoder().encode(updatedUser)

        let mockSession = MockURLSession(
            mockData: responseData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!
        let config = try RequestConfiguration(url: testURL, method: .PUT).withEncodableBody(updatedUser)

        // Act
        let response = try await client.request(for: config)

        // Assert
        #expect(try response.decode(TestUser.self) == updatedUser)
        #expect(response.statusCode == 200)
        await #expect(mockSession.lastRequest?.httpMethod == "PUT")
    }

    @Test("DELETE request")
    func testDeleteRequest() async throws {
        // Arrange
        let mockSession = MockURLSession(
            mockData: Data(),
            mockResponse: createMockHTTPResponse(statusCode: 204)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!

        // Act
        let response = try await client.request(for: RequestConfiguration(url: testURL, method: .DELETE))

        // Assert
        #expect(response.statusCode == 204)
        await #expect(mockSession.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Network timeout error")
    func testNetworkTimeout() async throws {
        // Arrange
        let mockSession = MockURLSession(
            mockError: URLError(.timedOut)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!

        // Act & Assert
        await #expect(throws: URLError.self) {
            _ = try await client.request(for: RequestConfiguration(url: testURL, method: .GET))
        }
    }

    @Test("Network error mapping")
    func testNetworkErrorMapping() async throws {
        let testCases: [(Int, NetworkError)] = [
            (401, .unauthorized),
            (403, .forbidden),
            (404, .notFound),
            (408, .requestTimeout),
            (429, .tooManyRequests(retryAfter: nil)),
            (500, .serverUnavailable),
            (502, .serverUnavailable),
            (503, .serverUnavailable)
        ]

        for (statusCode, expectedError) in testCases {
            // Arrange
            let mockSession = MockURLSession(
                mockData: Data(),
                mockResponse: createMockHTTPResponse(statusCode: statusCode)
            )
            let client = AsyncNetworkClient(session: mockSession)

            let testURL = URL(string: "https://api.example.com/test")!

            // rateLimitRetryDelay kept small here — this test only cares
            // that 429 maps to .tooManyRequests, not the real-world backoff
            // duration (that's covered by its own default in RequestConfiguration).
            let config = RequestConfiguration(url: testURL, method: .GET, rateLimitRetryDelay: 0.01)

            // Act & Assert
            await #expect(throws: expectedError) {
                _ = try await client.request(for: config)
            }

            await mockSession.reset()
        }
    }
}

// MARK: - Retry Logic Tests
@Suite("Retry Logic Tests")
struct RetryLogicTests {

    @Test("Successful retry after temporary failure")
    func testSuccessfulRetryAfterFailure() async throws {
        // Arrange
        let testUser = createTestUser()
        let jsonData = try JSONEncoder().encode(testUser)

        actor RetryMockSession: URLSessionProtocol, Sendable {
            var failureCount = 0
            var maxFailures: Int = 0
            var mockData: Data? = nil
            var mockResponse: URLResponse?

            init(
                failureCount: Int = 0,
                maxFailures: Int = 0,
                mockData: Data? = nil,
                mockResponse: URLResponse? = nil
            ) {
                self.failureCount = failureCount
                self.maxFailures = maxFailures
                self.mockData = mockData
                self.mockResponse = mockResponse
            }

            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                if failureCount < maxFailures {
                    failureCount += 1
                    return (mockData!, createMockHTTPResponse(statusCode: 500))
                }
                return (mockData!, mockResponse!)
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                if failureCount < maxFailures {
                    failureCount += 1
                    throw URLError(.networkConnectionLost)
                }
                return (mockData!, mockResponse!)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                if failureCount < maxFailures {
                    failureCount += 1
                    throw URLError(.networkConnectionLost)
                }

                return (URL(filePath: "//tmp/mock-download")!, mockResponse!)
            }

        }

        let retrySession = RetryMockSession(
            maxFailures: 2,
            mockData: jsonData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )

        let retryClient = AsyncNetworkClient(session: retrySession)
        let testURL = URL(string: "https://api.example.com/users/1")!

        let config = RequestConfiguration(
            url: testURL,
            method: .GET
        )

        // Act
        let response = try await retryClient.request(for: config)

        // Assert
        #expect(try response.decode(TestUser.self) == testUser)
        await #expect(retrySession.failureCount == 2) // Failed twice, then succeeded
    }

    @Test("429 with a Retry-After header waits that long, not the generic retryDelay")
    func testTooManyRequestsHonorsRetryAfterHeader() async throws {
        let testUser = createTestUser()
        let jsonData = try JSONEncoder().encode(testUser)

        actor RateLimitedSession: URLSessionProtocol, Sendable {
            var callCount = 0
            let jsonData: Data

            init(jsonData: Data) {
                self.jsonData = jsonData
            }

            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                callCount += 1
                if callCount == 1 {
                    let response = createMockHTTPResponse(statusCode: 429, headers: ["Retry-After": "1"])
                    return (Data(), response)
                }
                return (jsonData, createMockHTTPResponse(statusCode: 200))
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                throw URLError(.unsupportedURL)
            }
        }

        let session = RateLimitedSession(jsonData: jsonData)
        let client = AsyncNetworkClient(session: session)
        let testURL = URL(string: "https://api.example.com/users/1")!
        // rateLimitRetryDelay set high (30s) — if the fix incorrectly fell
        // back to it instead of honoring Retry-After: 1, this test's
        // elapsed-time assertion below would fail.
        let config = RequestConfiguration(url: testURL, method: .GET, rateLimitRetryDelay: 30.0)

        let start = Date()
        let response = try await client.request(for: config)
        let elapsed = Date().timeIntervalSince(start)

        #expect(try response.decode(TestUser.self) == testUser)
        await #expect(session.callCount == 2)
        #expect(elapsed >= 1.0 && elapsed < 5.0)
    }

    @Test("429 without a Retry-After header falls back to rateLimitRetryDelay, growing per attempt")
    func testTooManyRequestsFallsBackToRateLimitRetryDelay() async throws {
        actor AlwaysRateLimitedSession: URLSessionProtocol, Sendable {
            var callCount = 0

            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                callCount += 1
                return (Data(), createMockHTTPResponse(statusCode: 429))
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                throw URLError(.unsupportedURL)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                throw URLError(.unsupportedURL)
            }
        }

        let session = AlwaysRateLimitedSession()
        let client = AsyncNetworkClient(session: session)
        let testURL = URL(string: "https://api.example.com/users/1")!
        // retryCount: 2, rateLimitRetryDelay: 0.2 — expected wait between
        // the 2 attempts is 0.2 * 1 = 0.2s, small enough to keep this test
        // fast while still proving the fallback delay is actually used.
        let config = RequestConfiguration(url: testURL, method: .GET, retryCount: 2, rateLimitRetryDelay: 0.2)

        let start = Date()
        await #expect(throws: NetworkError.tooManyRequests(retryAfter: nil)) {
            _ = try await client.request(for: config)
        }
        let elapsed = Date().timeIntervalSince(start)

        await #expect(session.callCount == 2)
        #expect(elapsed >= 0.2)
    }

    @Test("Retry exhaustion leads to error")
    func testRetryExhaustionError() async throws {
        // Arrange
        actor AlwaysFailingSession: URLSessionProtocol, Sendable {
            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                throw URLError(.networkConnectionLost)
            }
            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                throw URLError(.networkConnectionLost)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                throw URLError(.networkConnectionLost)
            }
        }

        let failingSession = AlwaysFailingSession()
        let client = AsyncNetworkClient(session: failingSession)

        let testURL = URL(string: "https://api.example.com/users/1")!

        // Act & Assert
        await #expect(throws: URLError.self) {
            let config = RequestConfiguration(
                url: testURL,
                method: .GET
            )
            _ = try await client.request(for: config)
        }
    }

    @Test("No retry on client errors")
    func testNoRetryOnClientErrors() async throws {
        // Arrange
        actor ClientErrorSession: URLSessionProtocol, Sendable {
            var callCount = 0

            func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
                callCount += 1
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                return (Data(), response)
            }

            func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
                callCount += 1
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                return (Data(), response)
            }

            func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
                callCount += 1
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 400,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!

                return (URL(filePath: "//tmp/mock-download")!, response)
            }
        }

        let clientErrorSession = ClientErrorSession()
        let client = AsyncNetworkClient(session: clientErrorSession)

        let testURL = URL(string: "https://api.example.com/users/1")!

        // Act & Assert
        await #expect(throws: NetworkError.httpError(statusCode: 400, data: Data())) {
            let config = RequestConfiguration(
                url: testURL,
                method: .GET
            )
            _ = try await client.request(for: config)
        }

        // Should only be called once (no retries for client errors)
        await #expect(clientErrorSession.callCount == 1)
    }
}

// MARK: - Performance Tests
@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Concurrent requests performance")
    func testConcurrentRequestsPerformance() async throws {
        // Arrange
        let testUser = createTestUser()
        let jsonData = try JSONEncoder().encode(testUser)

        let mockSession = MockURLSession(
            mockData: jsonData,
            mockResponse: createMockHTTPResponse(statusCode: 200)
        )
        let client = AsyncNetworkClient(session: mockSession)

        let testURL = URL(string: "https://api.example.com/users/1")!
        let requestCount = 1000

        // Act
        let startTime = Date()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    do {
                        _ = try await client.request(for: RequestConfiguration(url: testURL, method: .GET))
                    } catch {
                        // Ignore errors for performance test
                    }
                }
            }
        }

        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)

        // Assert
        #expect(executionTime < 5.0) // Should complete within 5 seconds
        await #expect(mockSession.requestCount == requestCount)
    }
}
