//
//  VoiceCommand.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation

struct VoiceCommand: Identifiable, Codable {
    let id: UUID
    let message: String
    let timestamp: Date
    
    init(message: String) {
        self.id = UUID()
        self.message = message
        self.timestamp = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case timestamp
    }
}

struct VoiceResponse: Identifiable, Codable {
    let id: UUID
    let message: String
    let timestamp: Date
    let isUserMessage: Bool
    
    init(message: String, isUserMessage: Bool = false) {
        self.id = UUID()
        self.message = message
        self.timestamp = Date()
        self.isUserMessage = isUserMessage
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case timestamp
        case isUserMessage
    }
}
