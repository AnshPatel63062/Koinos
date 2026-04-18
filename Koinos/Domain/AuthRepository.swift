//
//  AuthRepository.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import Foundation

protocol AuthRepository {
    func getCurrentUserToken() async throws -> String
    func signInAnonymously() async throws
    func signInWithEmail(_ email: String, password: String) async throws
    func signOut() throws
    func isUserLoggedIn() -> Bool
}

enum AuthError: LocalizedError {
    case userNotLoggedIn
    case tokenExpired
    case invalidCredentials
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "No user is currently logged in"
        case .tokenExpired:
            return "Authentication token has expired"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return message
        }
    }
}
