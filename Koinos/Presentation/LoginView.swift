//
//  LoginView.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import SwiftUI

struct LoginView: View {
    var viewModel: LoginViewModel
    
    var body: some View {
        ZStack {
            if viewModel.isLoggedIn {
                // User is logged in, show logged-in state
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    Text("Successfully Logged In")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your authentication token is being managed securely.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red)
                            .foregroundStyle(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                // User is not logged in, show login options
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.key.fill")
                            .imageScale(.large)
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        
                        Text("Koinos Login")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.bottom, 20)
                    
                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    VStack(spacing: 12) {
                        TextField("Email", text: Binding(
                            get: { viewModel.email },
                            set: { viewModel.email = $0 }
                        ))
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        SecureField("Password", text: Binding(
                            get: { viewModel.password },
                            set: { viewModel.password = $0 }
                        ))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.signInWithEmail()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .cornerRadius(8)
                        } else {
                            Text("Sign In with Email")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Button(action: {
                        Task {
                            await viewModel.signInAnonymously()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray)
                                .cornerRadius(8)
                        } else {
                            Text("Continue Anonymously")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray)
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

#Preview {
    let mockAuthRepository = MockAuthRepository()
    let loginViewModel = LoginViewModel(authRepository: mockAuthRepository)
    return LoginView(viewModel: loginViewModel)
}

// Mock for Preview
class MockAuthRepository: AuthRepository {
    func getCurrentUserToken() async throws -> String {
        return "mock_token_preview"
    }
    
    func signInAnonymously() async throws {
        // Mock implementation
    }
    
    func signInWithEmail(_ email: String, password: String) async throws {
        // Mock implementation
    }
    
    func signOut() throws {
        // Mock implementation
    }
    
    func isUserLoggedIn() -> Bool {
        return false
    }
}
