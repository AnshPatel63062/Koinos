//
//  VoiceAssistantView.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import SwiftUI

struct VoiceAssistantView: View {
    var viewModel: VoiceAssistantViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)
                    Text("Koinos AI Assistant")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        viewModel.clearConversation()
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                        Button(action: {
                            viewModel.errorMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                }
            }
            .background(Color(.systemBackground))
            .borderBottom()
            
            // Messages
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Processing indicator
                        if viewModel.isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8, anchor: .center)
                                Text("Processing...")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("processing")
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.messages.count) {
                        withAnimation {
                            scrollProxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isProcessing) {
                        if viewModel.isProcessing {
                            withAnimation {
                                scrollProxy.scrollTo("processing", anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(.systemGray6))
            }
            
            // Input area
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("Type your message...", text: Binding(
                        get: { viewModel.currentInput },
                        set: { viewModel.currentInput = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .disabled(viewModel.isProcessing || viewModel.isMicListening)
                    
                    // Microphone button
                    Button(action: {
                        if viewModel.isMicListening {
                            Task {
                                await viewModel.stopVoiceInput()
                            }
                        } else {
                            viewModel.startVoiceInput()
                        }
                    }) {
                        Image(systemName: viewModel.isMicListening ? "mic.fill" : "mic")
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.isMicListening ? .red : .blue)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.isProcessing)
                    
                    // Send button
                    Button(action: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.isProcessing || viewModel.currentInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .borderTop()
        }
        .navigationTitle("Voice Assistant")
    }
}

// Message Bubble Component
struct MessageBubble: View {
    let message: VoiceResponse
    
    var body: some View {
        HStack {
            if message.isUserMessage {
                Spacer()
            }
            
            VStack(alignment: message.isUserMessage ? .trailing : .leading) {
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(message.isUserMessage ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(message.isUserMessage ? .white : .black)
                    .cornerRadius(12)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
            
            if !message.isUserMessage {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Border extensions
extension View {
    func borderTop() -> some View {
        self.border(Color(.separator), width: 1)
    }
    
    func borderBottom() -> some View {
        self.border(Color(.separator), width: 1)
    }
}

#Preview {
    let mockVoiceRepository = MockVoiceRepository()
    let viewModel = VoiceAssistantViewModel(voiceRepository: mockVoiceRepository)
    return VoiceAssistantView(viewModel: viewModel)
}

// Mock for Preview
class MockVoiceRepository: VoiceRepository {
    func processVoiceCommand(_ message: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(1000))
        return "Mock response to: \(message)"
    }
}
