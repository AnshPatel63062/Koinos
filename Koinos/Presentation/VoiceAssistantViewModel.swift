//
//  VoiceAssistantViewModel.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation
import Observation

@Observable
class VoiceAssistantViewModel {
    private let voiceRepository: VoiceRepository
    
    var messages: [VoiceResponse] = []
    var currentInput: String = ""
    var isProcessing: Bool = false
    var errorMessage: String?
    
    init(voiceRepository: VoiceRepository) {
        self.voiceRepository = voiceRepository
        // Add welcome message
        messages.append(VoiceResponse(message: "Hello! I'm the Koinos AI Assistant. How can I help you today?", isUserMessage: false))
    }
    
    @MainActor
    func sendMessage() async {
        // Validate input
        let trimmedInput = currentInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else {
            errorMessage = "Please enter a message"
            return
        }
        
        // Add user message to conversation
        let userMessage = VoiceResponse(message: trimmedInput, isUserMessage: true)
        messages.append(userMessage)
        currentInput = "" // Clear input field
        
        // Set processing state
        isProcessing = true
        errorMessage = nil
        
        do {
            // Call the voice repository
            let response = try await voiceRepository.processVoiceCommand(trimmedInput)
            
            // Add AI response to conversation
            let aiMessage = VoiceResponse(message: response, isUserMessage: false)
            messages.append(aiMessage)
        } catch let error as VoiceError {
            // Handle specific voice errors
            let errorResponse = VoiceResponse(message: "Error: \(error.errorDescription ?? "Unknown error occurred")", isUserMessage: false)
            messages.append(errorResponse)
            errorMessage = error.errorDescription
        } catch {
            // Handle generic errors
            let errorMessage = error.localizedDescription
            let errorResponse = VoiceResponse(message: "Error: \(errorMessage)", isUserMessage: false)
            messages.append(errorResponse)
            self.errorMessage = errorMessage
        }
        
        isProcessing = false
    }
    
    @MainActor
    func clearConversation() {
        messages = []
        messages.append(VoiceResponse(message: "Hello! I'm the Koinos AI Assistant. How can I help you today?", isUserMessage: false))
        currentInput = ""
        errorMessage = nil
    }
}
