//
//  VOICE_ASSISTANT_IMPLEMENTATION.md
//  Koinos
//

/*

 ═════════════════════════════════════════════════════════════════════════════
 KOINOS VOICE ASSISTANT - IMPLEMENTATION GUIDE
 ═════════════════════════════════════════════════════════════════════════════

 Complete MCP Client-Side Implementation with Clean Architecture

 ═════════════════════════════════════════════════════════════════════════════
 ARCHITECTURE OVERVIEW
 ═════════════════════════════════════════════════════════════════════════════

 Layer Structure:
 ┌─────────────────────────────────────────┐
 │  PRESENTATION LAYER                     │
 │  VoiceAssistantView ↔ ViewModel         │
 │  (@Observable, SwiftUI Chat UI)         │
 └────────────┬────────────────────────────┘
              │
 ┌────────────▼────────────────────────────┐
 │  DATA LAYER                             │
 │  KoinosVoiceRepository                  │
 │  (API communication)                    │
 └────────────┬────────────────────────────┘
              │
 ┌────────────▼────────────────────────────┐
 │  DOMAIN LAYER                           │
 │  VoiceRepository (protocol)             │
 │  VoiceCommand, VoiceResponse (entities) │
 │  VoiceError (errors)                    │
 └─────────────────────────────────────────┘


 ═════════════════════════════════════════════════════════════════════════════
 LAYER 1: DOMAIN LAYER
 ═════════════════════════════════════════════════════════════════════════════

 📄 VoiceCommand.swift
 ─────────────────────────────────────────────────────────────────────────────
 
 struct VoiceCommand: Identifiable, Codable
 - Properties:
   • id: UUID (unique identifier)
   • message: String (user's voice input)
   • timestamp: Date (when message was created)
 
 - Purpose: Represents a user's voice command to be sent to the backend
 
 
 📄 VoiceResponse.swift (in VoiceCommand.swift)
 ─────────────────────────────────────────────────────────────────────────────
 
 struct VoiceResponse: Identifiable, Codable
 - Properties:
   • id: UUID (unique identifier)
   • message: String (AI response or error message)
   • timestamp: Date (when response was received)
   • isUserMessage: Bool (true = user input, false = AI response)
 
 - Purpose: Represents messages in the conversation (user or AI)
 
 
 📄 VoiceRepository.swift
 ─────────────────────────────────────────────────────────────────────────────
 
 protocol VoiceRepository
 - Method:
   func processVoiceCommand(_ message: String) async throws -> String
 
 - Purpose: Defines the contract for voice processing
 - Input: User's message as String
 - Output: AI response as String
 - Throws: VoiceError on failure
 
 
 enum VoiceError: LocalizedError
 - Error Cases:
   • invalidMessage - Empty or invalid input
   • networkError(String) - Network/connection issues
   • serverUnavailable - Backend returns 503 Service Unavailable
   • decodingError(String) - Failed to decode JSON response
   • unauthorized - 401/403 authentication failure
   • unknown(String) - Other errors
 
 - Purpose: Comprehensive error handling for voice operations


 ═════════════════════════════════════════════════════════════════════════════
 LAYER 2: DATA LAYER
 ═════════════════════════════════════════════════════════════════════════════

 📄 KoinosVoiceRepository.swift
 ─────────────────────────────────────────────────────────────────────────────

 class KoinosVoiceRepository: VoiceRepository

 Initialization:
 init(
     authRepository: AuthRepository,
     baseURL: String = "http://localhost:8000",
     session: URLSession = .shared
 )

 Dependencies:
 - authRepository: AuthRepository (injected - provides Firebase token)
 - URLSession: For HTTP communication

 Implementation: processVoiceCommand(_ message: String) async throws -> String

 Flow:
 1. Validate message is not empty
    └─ Throws: VoiceError.invalidMessage
 
 2. Get Firebase ID token from authRepository
    └─ Calls: authRepository.getCurrentUserToken()
    └─ Throws: AuthError if token retrieval fails
 
 3. Build HTTP POST request
    └─ URL: http://localhost:8000/api/voice/
    └─ Method: POST
    └─ Headers:
       • Authorization: Bearer <firebase_id_token>
       • Content-Type: application/json
    └─ Body: { "message": "user input" }
 
 4. Execute URLSession request
    └─ Await response data
 
 5. Validate HTTP response status
    └─ 200-299: Success
    └─ 401/403: Throws VoiceError.unauthorized
    └─ 503: Throws VoiceError.serverUnavailable
    └─ 400-499: Throws VoiceError.networkError
    └─ 500-599: Throws VoiceError.networkError
 
 6. Decode response
    └─ Attempts JSON decoding first
    └─ Fallback to string encoding
    └─ Throws: VoiceError.decodingError
 
 7. Return AI response message

 Backend Integration:
 - Receives: POST /api/voice/ with Bearer token
 - Processes: Message through LangGraph agent
 - Agent calls: FastMCP tools (add_expense, search_expenses, delete_expense)
 - Returns: JSON { "message": "AI response" }


 ═════════════════════════════════════════════════════════════════════════════
 LAYER 3: PRESENTATION LAYER
 ═════════════════════════════════════════════════════════════════════════════

 📄 VoiceAssistantViewModel.swift
 ─────────────────────────────────────────────────────────────────────────────

 @Observable class VoiceAssistantViewModel

 Initialization:
 init(voiceRepository: VoiceRepository)

 State Properties:
 - messages: [VoiceResponse]
   • Array of all messages in conversation
   • Includes both user and AI messages
   • Each has timestamp and unique ID
   • Starts with welcome message
 
 - currentInput: String
   • User's text input in the input field
   • Cleared after sending
 
 - isProcessing: Bool
   • true while waiting for AI response
   • Used to show "Processing..." indicator
   • Disables send button
 
 - errorMessage: String?
   • Current error message (if any)
   • Displayed in error banner
   • Cleared when user sends new message

 Methods:

 @MainActor
 func sendMessage() async
 
 Flow:
 1. Validate input is not empty
 2. Add user message to messages array
 3. Clear currentInput field
 4. Set isProcessing = true
 5. Call voiceRepository.processVoiceCommand(message)
 6. Add AI response to messages array
 7. Handle any VoiceError
   - Add error message to conversation
   - Set errorMessage for display
 8. Set isProcessing = false

 
 @MainActor
 func clearConversation() async
 
 Purpose:
 - Resets entire conversation
 - Adds welcome message again
 - Clears error messages
 - Used by refresh button


 📄 VoiceAssistantView.swift
 ─────────────────────────────────────────────────────────────────────────────

 struct VoiceAssistantView: View

 UI Components:

 1. Header Section
    ├─ Mic icon + "Koinos AI Assistant" title
    └─ Refresh button to clear conversation
    
    Error Banner (conditional):
    ├─ Red background with error icon
    ├─ Error message text
    └─ Close button to dismiss

 2. Messages ScrollView
    ├─ Scrollable message history
    ├─ MessageBubble for each message
    │  ├─ User messages: Blue bubble, right-aligned
    │  ├─ AI messages: Gray bubble, left-aligned
    │  └─ Timestamp for each message
    └─ "Processing..." indicator during response
    
    Auto-scroll features:
    - Scrolls to new messages automatically
    - Scrolls to processing indicator

 3. Input Area
    ├─ TextField for message input
    ├─ Send button (paperplane icon)
    ├─ Button disabled during processing
    └─ Button disabled when input is empty

 Message Bubbles:
 - User messages (blue, right side)
 - AI messages (gray, left side)
 - Timestamps in caption font
 - Rounded corners for chat appearance

 FocusState:
 - Tracks if input field has focus
 - Can be used for keyboard management


 ═════════════════════════════════════════════════════════════════════════════
 LAYER 4: APP INTEGRATION
 ═════════════════════════════════════════════════════════════════════════════

 📄 KoinosApp.swift Updates
 ─────────────────────────────────────────────────────────────────────────────

 Dependency Injection Chain:

 1. authRepository = FirebaseAuthRepository()
    └─ Provides Firebase authentication

 2. voiceRepository = KoinosVoiceRepository(authRepository: authRepository)
    └─ Creates voice service with auth dependency

 3. voiceAssistantViewModel = VoiceAssistantViewModel(voiceRepository: voiceRepository)
    └─ Creates ViewModel for UI

 Scene Routing:

 if loginViewModel.isLoggedIn {
     TabView {
         ContentView(viewModel: koinosViewModel)
             .tabItem { Label("Info", systemImage: "info.circle") }
         
         VoiceAssistantView(viewModel: voiceAssistantViewModel)
             .tabItem { Label("Assistant", systemImage: "mic.circle") }
     }
 } else {
     LoginView(viewModel: loginViewModel)
 }

 Result:
 - Two tabs for authenticated users
 - Tab 1: Info (existing Koinos data)
 - Tab 2: Voice Assistant (new feature)
 - Automatic tab switching


 ═════════════════════════════════════════════════════════════════════════════
 DATA FLOW: USER SENDS MESSAGE
 ═════════════════════════════════════════════════════════════════════════════

 1. USER TYPES & SENDS
    VoiceAssistantView
    └─ User enters text in TextField
    └─ User taps send button
    └─ Task { await viewModel.sendMessage() } triggered

 2. VIEWMODEL PROCESSES
    VoiceAssistantViewModel.sendMessage()
    ├─ Validate input
    ├─ Add user message to messages array (blue bubble)
    ├─ Clear input field
    ├─ Set isProcessing = true
    └─ Call voiceRepository.processVoiceCommand(message)

 3. REPOSITORY COMMUNICATES
    KoinosVoiceRepository.processVoiceCommand()
    ├─ Get Firebase token from authRepository
    ├─ Build HTTP POST request
    │  └─ URL: http://localhost:8000/api/voice/
    │  └─ Header: Authorization: Bearer <token>
    │  └─ Body: { "message": "user input" }
    ├─ Execute URLSession.data()
    └─ Return response message

 4. BACKEND PROCESSES (FastAPI)
    /api/voice/ endpoint
    ├─ Receive POST request with Bearer token
    ├─ Verify token with Firebase Admin SDK
    ├─ Extract user_id from token
    ├─ Pass message to LangGraph agent
    ├─ Agent calls MCP tools as needed
    │  ├─ add_expense: Create expense
    │  ├─ search_expenses: Find expenses
    │  └─ delete_expense: Remove expense
    └─ Return: { "message": "AI response" }

 5. UI UPDATES
    VoiceAssistantView
    ├─ ViewModel receives AI response
    ├─ Add AI message to messages array (gray bubble)
    ├─ Set isProcessing = false
    ├─ MessageBubble renders new messages
    ├─ ScrollView auto-scrolls to bottom
    └─ User sees conversation flow naturally


 ═════════════════════════════════════════════════════════════════════════════
 ERROR HANDLING
 ═════════════════════════════════════════════════════════════════════════════

 Scenario 1: Empty Input
 ├─ Validation catches in sendMessage()
 └─ errorMessage = "Please enter a message"

 Scenario 2: Invalid Token / Unauthorized
 ├─ KoinosVoiceRepository catches 401/403
 ├─ Throws: VoiceError.unauthorized
 ├─ ViewModel catches error
 ├─ Adds error message to conversation
 └─ UI displays error banner

 Scenario 3: Network Error
 ├─ URLSession throws error
 ├─ Caught in KoinosVoiceRepository
 ├─ Throws: VoiceError.networkError
 ├─ ViewModel catches and displays error
 └─ Conversation shows error bubble

 Scenario 4: Service Unavailable (503)
 ├─ Backend returns HTTP 503
 ├─ Caught in processVoiceCommand
 ├─ Throws: VoiceError.serverUnavailable
 ├─ ViewModel displays user-friendly error
 └─ Message appears in chat: "Voice service temporarily unavailable"

 Scenario 5: Decoding Error
 ├─ Response cannot be parsed as JSON
 ├─ Fallback to string encoding
 ├─ If both fail: VoiceError.decodingError
 └─ ViewModel handles gracefully


 ═════════════════════════════════════════════════════════════════════════════
 SECURITY CONSIDERATIONS
 ═════════════════════════════════════════════════════════════════════════════

 ✓ Bearer Token Injection
   - Automatic from authRepository
   - No manual token handling
   - Prevents token leakage

 ✓ Firebase Verification
   - Backend verifies token with Firebase Admin SDK
   - User identity guaranteed
   - Cannot forge tokens

 ✓ Message Validation
   - Empty messages rejected client-side
   - Server-side validation by FastAPI

 ✓ Error Masking
   - User-friendly error messages
   - No sensitive information exposed
   - Debug details only in logs

 ✓ Thread Safety
   - @MainActor ensures UI thread safety
   - @Observable prevents state races
   - async/await proper concurrency


 ═════════════════════════════════════════════════════════════════════════════
 FEATURES
 ═════════════════════════════════════════════════════════════════════════════

 ✓ Chat Interface
   - Message bubbles with user/AI distinction
   - Timestamps for each message
   - Auto-scrolling to latest messages
   - Conversation history

 ✓ Real-time Feedback
   - "Processing..." indicator during response
   - Disabled send button during processing
   - Loading state prevents duplicate sends

 ✓ Error Handling
   - User-friendly error messages
   - Error banner at top
   - Errors added to conversation for context

 ✓ State Management
   - @Observable for reactive UI updates
   - Separate concerns: ViewModel vs View
   - Clean Architecture enforced

 ✓ Welcome Message
   - Greeting on app launch
   - Clear conversation to reset

 ✓ Responsive UI
   - TextField + send button layout
   - Adapts to different screen sizes
   - Keyboard support with @FocusState


 ═════════════════════════════════════════════════════════════════════════════
 TESTING
 ═════════════════════════════════════════════════════════════════════════════

 Preview Testing:
 ✓ VoiceAssistantView has MockVoiceRepository
 ✓ Simulates network delay (1 second)
 ✓ Returns mock response
 ✓ Chat UI displays correctly

 Manual Testing:
 1. Launch app and login
 2. Navigate to "Assistant" tab
 3. Type message in input field
 4. Tap send button
 5. Wait for "Processing..." indicator
 6. AI response appears in chat
 7. Test error handling: Stop backend → Try sending → See error
 8. Test recovery: Start backend → Send message → Works again
 9. Test clear: Tap refresh button → Conversation resets


 ═════════════════════════════════════════════════════════════════════════════
 DEPENDENCIES
 ═════════════════════════════════════════════════════════════════════════════

 - Firebase Auth iOS SDK (for ID tokens)
 - URLSession (Foundation)
 - SwiftUI (for UI)
 - Swift 5.9+ (for @Observable)


 ═════════════════════════════════════════════════════════════════════════════
 NEXT STEPS
 ═════════════════════════════════════════════════════════════════════════════

 1. [ ] Ensure FastAPI /api/voice/ endpoint is running
 2. [ ] Verify Firebase Admin SDK is initialized on backend
 3. [ ] Test with curl to verify endpoint works
 4. [ ] Test with Koinos app by sending messages
 5. [ ] Monitor backend logs to see token verification
 6. [ ] Test error scenarios (503, network failure)
 7. [ ] Add voice recording/transcription (future)
 8. [ ] Add response audio playback (future)

*/
