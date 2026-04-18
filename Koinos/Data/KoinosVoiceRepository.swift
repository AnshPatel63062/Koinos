//
//  KoinosVoiceRepository.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation

class KoinosVoiceRepository: VoiceRepository {
    private let authRepository: AuthRepository
    private let baseURL: String
    private let session: URLSession
    
    init(
        authRepository: AuthRepository,
        baseURL: String = "http://localhost:8000",
        session: URLSession = .shared
    ) {
        self.authRepository = authRepository
        self.baseURL = baseURL
        self.session = session
    }
    
    func processVoiceCommand(_ message: String) async throws -> String {
        // Validate message is not empty
        guard !message.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw VoiceError.invalidMessage
        }
        
        // Get authentication token
        let token = try await authRepository.getCurrentUserToken()
        
        // Build request URL
        guard let url = URL(string: baseURL + "/api/voice/") else {
            throw VoiceError.networkError("Invalid URL")
        }
        
        // Create request body
        let requestBody: [String: String] = ["message": message]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Configure URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Execute request
        let (responseData, response) = try await session.data(for: request)
        
        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoiceError.networkError("Invalid response type")
        }
        
        // Handle specific HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            return try decodeResponse(data: responseData)
        case 401, 403:
            throw VoiceError.unauthorized
        case 503:
            throw VoiceError.serverUnavailable
        case 400...499:
            throw VoiceError.networkError("Client error: \(httpResponse.statusCode)")
        case 500...599:
            throw VoiceError.networkError("Server error: \(httpResponse.statusCode)")
        default:
            throw VoiceError.unknown("HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func decodeResponse(data: Data) throws -> String {
        // Try to decode as JSON
        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = jsonObject["message"] as? String {
            return message
        }
        
        // Fallback to string encoding
        if let stringResponse = String(data: data, encoding: .utf8), !stringResponse.isEmpty {
            return stringResponse
        }
        
        throw VoiceError.decodingError("Could not decode response")
    }
}
