//
//  QUICK_START.md
//  Koinos
//

/*

 ╔════════════════════════════════════════════════════════════════════════╗
 ║              KOINOS AUTHENTICATION - QUICK START GUIDE                 ║
 ╚════════════════════════════════════════════════════════════════════════╝


 1️⃣  USER LOGS IN
 ─────────────────────────────────────────────────────────────────────────

 User opens app → LoginView displays
 User enters email/password → Clicks "Sign In with Email"
 OR → Clicks "Continue Anonymously"

 What happens behind the scenes:
 • LoginViewModel.signInWithEmail() or signInAnonymously() called
 • Calls FirebaseAuthRepository.signInWithEmail() or signInAnonymously()
 • Firebase Auth SDK authenticates user
 • User is now authenticated with Firebase
 • loginViewModel.isLoggedIn = true
 • UI switches to ContentView


 2️⃣  USER REQUESTS DATA
 ─────────────────────────────────────────────────────────────────────────

 User clicks "Fetch Info" button
 
 What happens:
 • ContentView calls KoinosViewModel.fetchInfo()
 • KoinosViewModel calls KoinosService.getInfo()
 • KoinosService makes HTTP request through AuthorizedNetworkClient
 • AuthorizedNetworkClient:
   1. Calls FirebaseAuthRepository.getCurrentUserToken()
   2. Gets current Firebase ID token from Auth.auth().currentUser
   3. Injects "Authorization: Bearer <token>" header
   4. Sends HTTP request to http://localhost:8000/...
 • FastAPI backend:
   1. Receives request with Bearer token
   2. Verifies token with Firebase Admin SDK
   3. Extracts verified user_id from token
   4. Returns response
 • Response decoded and displayed in UI


 3️⃣  USER LOGS OUT
 ─────────────────────────────────────────────────────────────────────────

 User clicks "Sign Out" in logged-in view
 
 What happens:
 • LoginView.signOut() calls LoginViewModel.signOut()
 • LoginViewModel calls FirebaseAuthRepository.signOut()
 • Firebase Auth SDK clears authentication state
 • loginViewModel.isLoggedIn = false
 • UI switches back to LoginView


 ═════════════════════════════════════════════════════════════════════════
 KEY POINTS
 ═════════════════════════════════════════════════════════════════════════

 ✓ Bearer Token Injection:
   Every HTTP request automatically includes the user's Firebase ID token
   No manual token management needed!

 ✓ Firebase Verification:
   Your FastAPI backend receives the token and verifies it with Firebase
   You can safely extract user_id from the verified token

 ✓ Clean Architecture:
   • Domain: Protocols and errors only
   • Data: Firebase implementation
   • Infrastructure: Network client
   • Presentation: SwiftUI views and @Observable ViewModels

 ✓ Modern Swift:
   • @Observable for state management
   • async/await for concurrency
   • MainActor for thread-safe UI updates

 ✓ Type Safe:
   All layers properly typed, compile-time safety


 ═════════════════════════════════════════════════════════════════════════
 FILE LOCATIONS
 ═════════════════════════════════════════════════════════════════════════

 Login Flow:
   Koinos/Presentation/LoginView.swift           ← Show login UI
   Koinos/Presentation/LoginViewModel.swift      ← Handle login state

 Authentication:
   Koinos/Domain/AuthRepository.swift            ← Protocol
   Koinos/Data/FirebaseAuthRepository.swift      ← Firebase implementation

 Network Requests:
   Koinos/Infrastructure/AuthorizedNetworkClient.swift  ← Bearer token injection

 Main Data Fetching:
   Koinos/Presentation/ContentView.swift         ← Show data UI
   Koinos/Presentation/KoinosViewModel.swift     ← Fetch data state
   Koinos/Data/KoinosService.swift               ← Call MCP tools

 App Entry Point:
   Koinos/KoinosApp.swift                        ← Dependency injection


 ═════════════════════════════════════════════════════════════════════════
 ENVIRONMENT SETUP NEEDED
 ═════════════════════════════════════════════════════════════════════════

 Before running the app, ensure:

 1. Firebase Configuration:
    [ ] GoogleService-Info.plist added to project
    [ ] Firebase Auth enabled in console
    [ ] Authentication providers configured

 2. FastAPI Backend:
    [ ] Running at http://localhost:8000
    [ ] Firebase Admin SDK initialized
    [ ] Token verification endpoint implemented
    [ ] get_info MCP tool available

 3. Xcode Project:
    [ ] Firebase SDK installed (via CocoaPods or SPM)
    [ ] MCP Swift SDK installed
    [ ] Build phases configured


 ═════════════════════════════════════════════════════════════════════════
 DEBUGGING TIPS
 ═════════════════════════════════════════════════════════════════════════

 Token Not Injected:
   • Check: FirebaseAuthRepository.getCurrentUserToken() is called
   • Debug: Add print statement in AuthorizedNetworkClient.request()
   • Verify: Auth.auth().currentUser exists before network call

 Login Fails:
   • Check: Email/password correct
   • Debug: Catch AuthError in catch block
   • Verify: Firebase Auth enabled in console

 Backend Rejects Request:
   • Check: Token format is "Bearer <token>"
   • Debug: Log token in FastAPI middleware
   • Verify: Firebase Admin SDK initialized on backend
   • Test: Use Firebase tokens in other tools first

 UI Not Updating:
   • Check: @Observable decorator on ViewModel
   • Debug: Ensure @MainActor on async methods
   • Verify: State properties accessible (not private)


 ═════════════════════════════════════════════════════════════════════════
 TESTING THE FLOW
 ═════════════════════════════════════════════════════════════════════════

 1. Run Koinos app
 2. Login with test email or anonymously
 3. Should see "Successfully Logged In"
 4. Click "Fetch Info"
 5. Should see data from backend
 6. Backend console should show verified user_id in request
 7. Click "Sign Out"
 8. Should return to login screen


 ═════════════════════════════════════════════════════════════════════════
 DOCUMENTATION FILES
 ═════════════════════════════════════════════════════════════════════════

 [ ] AUTHENTICATION_ARCHITECTURE.md    ← Detailed layer documentation
 [ ] ARCHITECTURE_DIAGRAM.txt          ← Visual architecture and flow
 [ ] IMPLEMENTATION_CHECKLIST.md       ← Complete checklist of all features
 [ ] QUICK_START.md                    ← This file


*/
