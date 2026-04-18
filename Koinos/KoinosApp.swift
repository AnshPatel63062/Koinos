//
//  KoinosApp.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import SwiftUI
import FirebaseCore

@main
struct KoinosApp: App {
    private let authRepository: AuthRepository
    private let loginViewModel: LoginViewModel
    private let koinosViewModel: KoinosViewModel
    private let voiceAssistantViewModel: VoiceAssistantViewModel
    private let networkClient: AuthorizedNetworkClient
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Authentication Layer
        self.authRepository = FirebaseAuthRepository()
        self.loginViewModel = LoginViewModel(authRepository: authRepository)
        
        // Network Layer
        self.networkClient = AuthorizedNetworkClient(
            authRepository: authRepository,
            baseURL: "http://localhost:8000"
        )
        
        // Koinos Layer
        let koinosService = KoinosService(client: MCPClient(baseURL: "http://localhost:8000/sse"))
        self.koinosViewModel = KoinosViewModel(repository: koinosService)
        
        // Voice Assistant Layer
        let voiceRepository = KoinosVoiceRepository(authRepository: authRepository)
        self.voiceAssistantViewModel = VoiceAssistantViewModel(voiceRepository: voiceRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            if loginViewModel.isLoggedIn {
                TabView {
                    ContentView(viewModel: koinosViewModel)
                        .tabItem {
                            Label("Info", systemImage: "info.circle")
                        }
                    
                    VoiceAssistantView(viewModel: voiceAssistantViewModel)
                        .tabItem {
                            Label("Assistant", systemImage: "mic.circle")
                        }
                }
            } else {
                LoginView(viewModel: loginViewModel)
            }
        }
    }
}
