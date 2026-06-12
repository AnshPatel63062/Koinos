//
//  ExpenseRepository.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation

protocol ExpenseRepository {
    func fetchExpenses() async throws -> [Expense]
    func deleteExpense(_ expenseId: String) async throws
    func updateExpense(_ expense: Expense) async throws
    func createExpense(amount: Double, category: String, description: String?) async throws -> Expense
}

enum ExpenseError: LocalizedError {
    case invalidAmount
    case invalidCategory
    case networkError(String)
    case notFound
    case unauthorized
    case decodingError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid amount"
        case .invalidCategory:
            return "Invalid category"
        case .networkError(let message):
            return "Network error: \(message)"
        case .notFound:
            return "Expense not found"
        case .unauthorized:
            return "Unauthorized - please login again"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
