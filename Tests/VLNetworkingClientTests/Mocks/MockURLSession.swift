//
//  MockURLSession.swift
//  HttpClient
//
//  Created by James Langdon on 7/16/25.
//

import Testing
import Foundation
@testable import VLNetworkingClient

// MARK: - Mock URLSession
actor MockURLSession: URLSessionProtocol, Sendable {
    var mockData: Data? = nil
    var mockResponse: URLResponse?
    var mockError: Error?
    var requestCount = 0
    var lastRequest: URLRequest?
    
    init(
        mockData: Data? = nil,
        mockResponse: URLResponse? = nil,
        mockError: Error? = nil,
        requestCount: Int = 0,
        lastRequest: URLRequest? = nil
    ) {
        self.mockData = mockData
        self.mockResponse = mockResponse
        self.mockError = mockError
        self.requestCount = requestCount
        self.lastRequest = lastRequest
    }
    
    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (Data, URLResponse) {
        requestCount += 1
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData,
              let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
    
    func upload(for request: URLRequest, fromFile: URL) async throws -> (Data, URLResponse) {
        requestCount += 1
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData,
              let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, response)
    }
    
    func download(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
        requestCount += 1
        lastRequest = request
        
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (request.url!, response)
    }
    
    func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        requestCount = 0
        lastRequest = nil
    }
}
