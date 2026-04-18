//
//  FirebaseAuthRepository.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import Foundation
import FirebaseAuth

class FirebaseAuthRepository: AuthRepository {
    private let auth = Auth.auth()
    
    func getCurrentUserToken() async throws -> String {
        guard let currentUser = auth.currentUser else {
            throw AuthError.userNotLoggedIn
        }
        
        do {
            let token = try await currentUser.getIDToken(forcingRefresh: false)
            return token
        } catch {
            throw AuthError.tokenExpired
        }
    }
    
    func signInAnonymously() async throws {
        do {
            _ = try await auth.signInAnonymously()
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    func signInWithEmail(_ email: String, password: String) async throws {
        do {
            _ = try await auth.signIn(withEmail: email, password: password)
        } catch let error as NSError {
            if error.code == AuthErrorCode.userNotFound.rawValue ||
               error.code == AuthErrorCode.wrongPassword.rawValue {
                throw AuthError.invalidCredentials
            }
            throw AuthError.networkError(error.localizedDescription)
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func isUserLoggedIn() -> Bool {
        return auth.currentUser != nil
    }
}
