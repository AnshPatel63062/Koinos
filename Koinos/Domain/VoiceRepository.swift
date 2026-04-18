//
//  VoiceRepository.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation

protocol VoiceRepository {
    func processVoiceCommand(_ message: String) async throws -> String
}

enum VoiceError: LocalizedError {
    case invalidMessage
    case networkError(String)
    case serverUnavailable
    case decodingError(String)
    case unauthorized
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidMessage:
            return "Invalid message format"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverUnavailable:
            return "Voice service is temporarily unavailable (503)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .unauthorized:
            return "Unauthorized - authentication token invalid"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
