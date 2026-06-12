//
//  ExpenseListView.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import SwiftUI

struct ExpenseListView: View {
    var viewModel: ExpenseListViewModel
    @State private var selectedExpense: Expense?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.expenses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "receipt")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        Text("No Expenses")
                            .font(.headline)
                        Text("Pull down to refresh or add your first expense")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.expenses) { expense in
                            NavigationLink(value: expense) {
                                ExpenseRowView(expense: expense)
                            }
                        }
                        .onDelete(perform: handleDelete)
                    }
                    .refreshable {
                        await viewModel.refreshExpenses()
                    }
                }
                
                // Error Banner
                if let error = viewModel.errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                            Button(action: { viewModel.errorMessage = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        Spacer()
                    }
                }
            }
            .navigationTitle("Expenses")
            .navigationDestination(for: Expense.self) { expense in
                ExpenseDetailView(viewModel: ExpenseDetailViewModel(
                    expenseRepository: MockExpenseRepository(),
                    expense: expense
                ))
            }
            .task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    private func handleDelete(at offsets: IndexSet) {
        for index in offsets {
            let expense = viewModel.expenses[index]
            Task {
                await viewModel.deleteExpense(expense.id)
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: Expense.Category(rawValue: expense.category)?.systemImage ?? "circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Expense Details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category)
                    .font(.headline)
                if let description = expense.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(formatDate(expense.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Amount
            Text(formatCurrency(expense.amount))
                .font(.headline)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// Mock for preview
class MockExpenseRepository: ExpenseRepository {
    func fetchExpenses() async throws -> [Expense] {
        return [
            Expense(id: "1", amount: 25.50, category: "Food", date: Date(), description: "Lunch"),
            Expense(id: "2", amount: 100.00, category: "Transportation", date: Date().addingTimeInterval(-86400), description: "Gas"),
            Expense(id: "3", amount: 45.99, category: "Entertainment", date: Date().addingTimeInterval(-172800), description: "Movie tickets")
        ]
    }
    
    func deleteExpense(_ expenseId: String) async throws {}
    
    func updateExpense(_ expense: Expense) async throws {}
    
    func createExpense(amount: Double, category: String, description: String?) async throws -> Expense {
        return Expense(id: UUID().uuidString, amount: amount, category: category, date: Date(), description: description)
    }
}

#Preview {
    let mockRepo = MockExpenseRepository()
    let viewModel = ExpenseListViewModel(expenseRepository: mockRepo)
    return ExpenseListView(viewModel: viewModel)
}
