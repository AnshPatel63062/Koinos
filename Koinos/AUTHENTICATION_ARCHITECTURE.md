//
//  AUTHENTICATION_ARCHITECTURE.md
//  Koinos
//
//  Complete Clean Architecture Authentication Layer Documentation
//

/*
 
 AUTHENTICATION LAYER IMPLEMENTATION - CLEAN ARCHITECTURE
 
 ===============================================================================
 LAYER 1: DOMAIN LAYER
 ===============================================================================
 
 File: Domain/AuthRepository.swift
 - AuthRepository protocol: Defines authentication contract
   - getCurrentUserToken() async throws -> String
   - signInAnonymously() async throws
   - signInWithEmail(_ email: String, password: String) async throws
   - signOut() throws
   - isUserLoggedIn() -> Bool
 
 - AuthError enum: Comprehensive error handling
   - userNotLoggedIn
   - tokenExpired
   - invalidCredentials
   - networkError(String)
   - unknown(String)
 
 
 ===============================================================================
 LAYER 2: DATA LAYER
 ===============================================================================
 
 File: Data/FirebaseAuthRepository.swift
 - Concrete implementation of AuthRepository protocol
 - Uses Firebase Auth iOS SDK
 - getCurrentUserToken():
   * Retrieves Auth.auth().currentUser
   * Calls getIDToken(forcingRefresh: false)
   * Returns Bearer token string
   * Throws AuthError.userNotLoggedIn if no user exists
   * Throws AuthError.tokenExpired on token failure
 
 - signInAnonymously():
   * Calls Auth.auth().signInAnonymously()
   * No credentials required
   * Throws NetworkError on failure
 
 - signInWithEmail(_:password:):
   * Calls Auth.auth().signIn(withEmail:password:)
   * Handles AuthErrorCode.userNotFound and wrongPassword
   * Maps to AuthError.invalidCredentials
 
 - signOut():
   * Calls Auth.auth().signOut()
   * Clears authenticated user
 
 - isUserLoggedIn():
   * Returns Auth.auth().currentUser != nil
 
 
 ===============================================================================
 LAYER 3: INFRASTRUCTURE LAYER
 ===============================================================================
 
 File: Infrastructure/AuthorizedNetworkClient.swift
 - Wraps URLSession for authenticated HTTP requests
 - Automatic Bearer token injection
 - Flow:
   1. Request is initiated with endpoint, method, body
   2. Calls authRepository.getCurrentUserToken()
   3. Sets "Authorization: Bearer <token>" header
   4. Executes URLSession request
   5. Validates HTTP status (200-299)
   6. Returns decoded JSON or raw data
 
 - request<T: Decodable>():
   * Generic method for JSON responses
   * Automatically decodes response to type T
 
 - requestData():
   * Raw data endpoint for non-JSON responses
 
 - NetworkError enum:
   * invalidURL
   * invalidResponse
   * httpError(Int)
   * decodingError(String)
 
 - baseURL: Configurable (default: http://localhost:8000)
 
 
 ===============================================================================
 LAYER 4: PRESENTATION LAYER
 ===============================================================================
 
 File: Presentation/LoginViewModel.swift
 - @Observable class for SwiftUI state management
 - Dependencies: AuthRepository (injected)
 - State Properties:
   * email: String (email input)
   * password: String (password input)
   * isLoading: Bool (loading indicator)
   * errorMessage: String? (error display)
   * isLoggedIn: Bool (authentication state)
 
 - Methods:
   * signInAnonymously(): Async sign-in without credentials
   * signInWithEmail(): Async email/password sign-in with validation
   * signOut(): Synchronous logout with state reset
 
 - All async methods run on MainActor for UI updates
 
 File: Presentation/LoginView.swift
 - SwiftUI View for authentication UI
 - Conditional UI based on viewModel.isLoggedIn:
   * False: Shows login form with email/password fields
   * True: Shows success screen with sign-out button
 
 - Features:
   * Email TextField with email keyboard
   * SecureField for password input
   * "Sign In with Email" button
   * "Continue Anonymously" button
   * Error message display
   * Loading state with ProgressView
   * Mock preview with MockAuthRepository
 
 
 ===============================================================================
 LAYER 5: APP INITIALIZATION (KoinosApp.swift)
 ===============================================================================
 
 Dependency Injection Chain:
 1. FirebaseApp.configure() - Firebase SDK initialization
 2. authRepository = FirebaseAuthRepository()
 3. loginViewModel = LoginViewModel(authRepository: authRepository)
 4. networkClient = AuthorizedNetworkClient(
       authRepository: authRepository,
       baseURL: "http://localhost:8000"
    )
 5. koinosService = KoinosService(client: MCPClient(...))
 6. koinosViewModel = KoinosViewModel(repository: koinosService)
 
 Scene routing:
 - If loginViewModel.isLoggedIn: Show ContentView with koinosViewModel
 - Else: Show LoginView with loginViewModel
 
 
 ===============================================================================
 USAGE FLOW
 ===============================================================================
 
 1. USER LAUNCHES APP
    ↓
    KoinosApp initializes Firebase and dependency injection
    LoginView displays (not logged in)
 
 2. USER SIGNS IN
    ↓
    LoginView.signInWithEmail() calls LoginViewModel.signInWithEmail()
    LoginViewModel calls authRepository.signInWithEmail(email, password)
    FirebaseAuthRepository calls Firebase Auth SDK
    User authenticated, loginViewModel.isLoggedIn = true
    ↓
    Scene routing detects isLoggedIn = true
    ContentView displays
 
 3. CONTENT VIEW MAKES API CALL
    ↓
    ContentView calls koinosViewModel.fetchInfo()
    KoinosViewModel calls repository.getInfo()
    KoinosService needs to make HTTP request
    ↓
    AuthorizedNetworkClient.request() called
    Retrieves token: authRepository.getCurrentUserToken()
    Gets current Firebase ID token
    Injects "Authorization: Bearer <token>" header
    Sends request to FastAPI backend
    Backend validates token with Firebase Admin SDK
    Response decoded and returned to ViewModel
    ↓
    ViewModel updates infoData @Observable state
    UI automatically updates
 
 4. USER SIGNS OUT
    ↓
    LoginView.signOut() calls LoginViewModel.signOut()
    LoginViewModel calls authRepository.signOut()
    FirebaseAuthRepository calls Firebase Auth SDK
    User logged out, loginViewModel.isLoggedIn = false
    ↓
    Scene routing detects isLoggedIn = false
    LoginView displays again
 
 
 ===============================================================================
 SECURITY CONSIDERATIONS
 ===============================================================================
 
 ✓ Token Injection: All requests automatically include Bearer token
 ✓ Firebase Verification: Backend verifies token with Firebase Admin SDK
 ✓ SecureField: Password input masked on screen
 ✓ Error Handling: User not logged in errors properly caught
 ✓ MainActor: All UI updates on main thread (thread-safe)
 ✓ Async/Await: No callback hell, structured concurrency
 
 TODO (Future Enhancements):
 - Keychain storage for persistent authentication
 - Automatic token refresh before expiration
 - Biometric authentication (Face ID / Touch ID)
 - Session timeout management
 - Token revocation on security breach
 
 */
