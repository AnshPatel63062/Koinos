//
//  ExpenseListViewModel.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation
import Observation

@Observable
class ExpenseListViewModel {
    private let expenseRepository: ExpenseRepository
    
    var expenses: [Expense] = []
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var errorMessage: String?
    
    init(expenseRepository: ExpenseRepository) {
        self.expenseRepository = expenseRepository
    }
    
    @MainActor
    func fetchExpenses() async {
        isLoading = true
        errorMessage = nil
        
        do {
            expenses = try await expenseRepository.fetchExpenses()
        } catch let error as ExpenseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshExpenses() async {
        isRefreshing = true
        errorMessage = nil
        
        do {
            expenses = try await expenseRepository.fetchExpenses()
        } catch let error as ExpenseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    @MainActor
    func deleteExpense(_ expenseId: String) async {
        do {
            try await expenseRepository.deleteExpense(expenseId)
            // Remove from local list
            expenses.removeAll { $0.id == expenseId }
        } catch let error as ExpenseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    func loadInitialData() async {
        if expenses.isEmpty {
            await fetchExpenses()
        }
    }
}
