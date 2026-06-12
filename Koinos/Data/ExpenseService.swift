//
//  ExpenseService.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation

class ExpenseService: ExpenseRepository {
    private let authRepository: AuthRepository
    private let baseURL: String
    private let session: URLSession
    
    init(
        authRepository: AuthRepository,
        baseURL: String = "http://localhost:8000",
        session: URLSession = .shared
    ) {
        self.authRepository = authRepository
        self.baseURL = baseURL
        self.session = session
    }
    
    func fetchExpenses() async throws -> [Expense] {
        let token = try await authRepository.getCurrentUserToken()
        guard let url = URL(string: baseURL + "/api/expenses/") else {
            throw ExpenseError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExpenseError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try decodeExpenses(data: data)
        case 401, 403:
            throw ExpenseError.unauthorized
        case 404:
            throw ExpenseError.notFound
        case 500...599:
            throw ExpenseError.networkError("Server error: \(httpResponse.statusCode)")
        default:
            throw ExpenseError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    func deleteExpense(_ expenseId: String) async throws {
        let token = try await authRepository.getCurrentUserToken()
        guard let url = URL(string: baseURL + "/api/expenses/\(expenseId)") else {
            throw ExpenseError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExpenseError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw ExpenseError.unauthorized
        case 404:
            throw ExpenseError.notFound
        case 500...599:
            throw ExpenseError.networkError("Server error: \(httpResponse.statusCode)")
        default:
            throw ExpenseError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    func updateExpense(_ expense: Expense) async throws {
        let token = try await authRepository.getCurrentUserToken()
        guard let url = URL(string: baseURL + "/api/expenses/\(expense.id)") else {
            throw ExpenseError.networkError("Invalid URL")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(expense)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExpenseError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            _ = try decodeExpense(data: data)
        case 401, 403:
            throw ExpenseError.unauthorized
        case 404:
            throw ExpenseError.notFound
        case 500...599:
            throw ExpenseError.networkError("Server error: \(httpResponse.statusCode)")
        default:
            throw ExpenseError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    func createExpense(amount: Double, category: String, description: String?) async throws -> Expense {
        guard amount > 0 else {
            throw ExpenseError.invalidAmount
        }
        
        let token = try await authRepository.getCurrentUserToken()
        guard let url = URL(string: baseURL + "/api/expenses/") else {
            throw ExpenseError.networkError("Invalid URL")
        }
        
        let requestBody: [String: Any] = [
            "amount": amount,
            "category": category,
            "description": description ?? ""
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExpenseError.networkError("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try decodeExpense(data: data)
        case 401, 403:
            throw ExpenseError.unauthorized
        case 500...599:
            throw ExpenseError.networkError("Server error: \(httpResponse.statusCode)")
        default:
            throw ExpenseError.networkError("HTTP \(httpResponse.statusCode)")
        }
    }
    
    private func decodeExpenses(data: Data) throws -> [Expense] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let expenses = try? decoder.decode([Expense].self, from: data) {
            return expenses
        }
        
        if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let expensesData = response["expenses"] as? [[String: Any]] {
            let jsonData = try JSONSerialization.data(withJSONObject: expensesData)
            return try decoder.decode([Expense].self, from: jsonData)
        }
        
        throw ExpenseError.decodingError("Could not decode expenses")
    }
    
    private func decodeExpense(data: Data) throws -> Expense {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let expense = try? decoder.decode(Expense.self, from: data) {
            return expense
        }
        
        if let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let expenseData = response["expense"] as? [String: Any] {
            let jsonData = try JSONSerialization.data(withJSONObject: expenseData)
            return try decoder.decode(Expense.self, from: jsonData)
        }
        
        throw ExpenseError.decodingError("Could not decode expense")
    }
}
