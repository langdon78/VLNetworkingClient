//
//  AsyncClientTests.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Testing
@testable import VLNetworkingClient
import Foundation

// MARK: - Test Helper Functions
func createMockHTTPResponse(statusCode: Int = 200, url: URL? = nil) -> HTTPURLResponse {
    let responseURL = url ?? URL(string: "https://api.example.com/test")!
    return HTTPURLResponse(
        url: responseURL,
        statusCode: statusCode,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
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
        let response: NetworkResponse<TestUser> = try await client.get(from: testURL)
        
        // Assert
        #expect(response.data == testUser)
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
        
        // Act
        let response: NetworkResponse<TestUser> = try await client.post(to: testURL, body: inputUser)
        
        // Assert
        #expect(response.data == responseUser)
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
            let _: NetworkResponse<TestUser> = try await client.get(from: testURL)
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
            let _: NetworkResponse<TestUser> = try await client.get(from: testURL)
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
            let _: NetworkResponse<TestUser> = try await client.get(from: testURL)
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
        let response: NetworkResponse<TestUser> = try await client.request(config)
        
        // Assert
        #expect(response.data == testUser)
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
        var testURLRequest = URLRequest(url: testURL)
        testURLRequest.addValue("Bearer default-token", forHTTPHeaderField: "Authorization")
        testURLRequest.addValue("TestApp/1.0", forHTTPHeaderField: "User-Agent")
        
        // Act
        let response: NetworkResponse<TestUser> = try await client.get(from: testURLRequest.url!, headers: testURLRequest.allHTTPHeaderFields!)
        
        // Assert
        #expect(response.data == testUser)
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
        let response = try await client.request(config)
        
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
        let response = try await client.downloadFile(config, to: destination)
        
        // Assert
        #expect(response.data == destination)
        #expect(response.statusCode == 200)
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
        
        // Act
        let response: NetworkResponse<TestUser> = try await client.put(to: testURL, body: updatedUser)
        
        // Assert
        #expect(response.data == updatedUser)
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
        let response = try await client.delete(from: testURL)
        
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
            let _: NetworkResponse<TestUser> = try await client.get(from: testURL)
        }
    }
    
    @Test("Network error mapping")
    func testNetworkErrorMapping() async throws {
        let testCases: [(Int, NetworkError)] = [
            (401, .unauthorized),
            (403, .forbidden),
            (404, .notFound),
            (408, .requestTimeout),
            (429, .tooManyRequests),
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
            
            // Act & Assert
            await #expect(throws: expectedError) {
                let _: NetworkResponse<TestUser> = try await client.get(from: testURL)
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
        let response: NetworkResponse<TestUser> = try await retryClient.request(config)
        
        // Assert
        #expect(response.data == testUser)
        await #expect(retrySession.failureCount == 2) // Failed twice, then succeeded
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
            let _: NetworkResponse<TestUser> = try await client.request(config)
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
            let _: NetworkResponse<TestUser> = try await client.request(config)
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
                        let _: NetworkResponse<TestUser> = try await client.get(from: testURL)
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
