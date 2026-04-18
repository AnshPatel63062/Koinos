//
//  LoginViewModel.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import Foundation
import Observation

@Observable
class LoginViewModel {
    private let authRepository: AuthRepository
    
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var isLoggedIn: Bool = false
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        self.isLoggedIn = authRepository.isUserLoggedIn()
    }
    
    @MainActor
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepository.signInAnonymously()
            isLoggedIn = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription ?? "Unknown error"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func signInWithEmail() async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Email and password are required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authRepository.signInWithEmail(email, password: password)
            isLoggedIn = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription ?? "Unknown error"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() {
        do {
            try authRepository.signOut()
            isLoggedIn = false
            email = ""
            password = ""
            errorMessage = nil
        } catch let error as AuthError {
            errorMessage = error.errorDescription ?? "Failed to sign out"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
