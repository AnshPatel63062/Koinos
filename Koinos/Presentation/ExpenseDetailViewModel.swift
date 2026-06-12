//
//  ExpenseDetailViewModel.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation
import Observation

@Observable
class ExpenseDetailViewModel {
    private let expenseRepository: ExpenseRepository
    
    var expense: Expense
    var isEditing: Bool = false
    var isSaving: Bool = false
    var isDeleting: Bool = false
    var errorMessage: String?
    var showDeleteConfirmation: Bool = false
    
    // Editing fields
    var editedAmount: String
    var editedCategory: String
    var editedDescription: String
    var editedDate: Date
    
    init(expenseRepository: ExpenseRepository, expense: Expense) {
        self.expenseRepository = expenseRepository
        self.expense = expense
        
        self.editedAmount = String(format: "%.2f", expense.amount)
        self.editedCategory = expense.category
        self.editedDescription = expense.description ?? ""
        self.editedDate = expense.date
    }
    
    @MainActor
    func saveExpense() async {
        guard let amount = Double(editedAmount), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        var updatedExpense = expense
        updatedExpense.amount = amount
        updatedExpense.category = editedCategory
        updatedExpense.date = editedDate
        updatedExpense.description = editedDescription.isEmpty ? nil : editedDescription
        
        do {
            try await expenseRepository.updateExpense(updatedExpense)
            expense = updatedExpense
            isEditing = false
        } catch let error as ExpenseError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSaving = false
    }
    
    @MainActor
    func deleteExpense() async {
        isDeleting = true
        errorMessage = nil
        
        do {
            try await expenseRepository.deleteExpense(expense.id)
            // Deletion successful - will be handled by caller via dismiss
        } catch let error as ExpenseError {
            errorMessage = error.errorDescription
            isDeleting = false
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
        }
    }
    
    @MainActor
    func cancelEditing() {
        isEditing = false
        editedAmount = String(format: "%.2f", expense.amount)
        editedCategory = expense.category
        editedDescription = expense.description ?? ""
        editedDate = expense.date
        errorMessage = nil
    }
    
    @MainActor
    func startEditing() {
        isEditing = true
    }
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
