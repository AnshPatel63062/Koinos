//
//  ExpenseDetailView.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import SwiftUI

struct ExpenseDetailView: View {
    var viewModel: ExpenseDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: Expense.Category(rawValue: viewModel.expense.category)?.systemImage ?? "circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.expense.category)
                                .font(.headline)
                            Text(viewModel.formatDate(viewModel.expense.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.formatCurrency(viewModel.expense.amount))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if viewModel.isEditing {
                        // Edit Mode
                        EditExpenseForm(viewModel: viewModel)
                    } else {
                        // View Mode
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(label: "Amount", value: viewModel.formatCurrency(viewModel.expense.amount))
                            Divider()
                            DetailRow(label: "Category", value: viewModel.expense.category)
                            Divider()
                            DetailRow(label: "Date", value: viewModel.formatDate(viewModel.expense.date))
                            
                            if let description = viewModel.expense.description, !description.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(description)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Delete Button
                        Button(role: .destructive, action: {
                            viewModel.showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Expense")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isDeleting)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            
            // Error Banner
            if let error = viewModel.errorMessage {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
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
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isEditing {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            viewModel.cancelEditing()
                        }
                        
                        Button("Save") {
                            Task {
                                await viewModel.saveExpense()
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                } else {
                    Button("Edit") {
                        viewModel.startEditing()
                    }
                }
            }
        }
        .confirmationDialog("Delete Expense?", isPresented: Binding(
            get: { viewModel.showDeleteConfirmation },
            set: { viewModel.showDeleteConfirmation = $0 }
        )) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteExpense()
                    if viewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

struct EditExpenseForm: View {
    var viewModel: ExpenseDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Amount Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("0.00", text: Binding(
                    get: { viewModel.editedAmount },
                    set: { viewModel.editedAmount = $0 }
                ))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }
            
            // Category Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Category", selection: Binding(
                    get: { viewModel.editedCategory },
                    set: { viewModel.editedCategory = $0 }
                )) {
                    ForEach(Expense.Category.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Date Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker("", selection: Binding(
                    get: { viewModel.editedDate },
                    set: { viewModel.editedDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
            }
            
            // Description Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: Binding(
                    get: { viewModel.editedDescription },
                    set: { viewModel.editedDescription = $0 }
                ))
                    .frame(height: 100)
                    .textFieldStyle(.roundedBorder)
                    .border(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let mockRepo = MockExpenseRepository()
    let expense = Expense(id: "1", amount: 25.50, category: "Food", date: Date(), description: "Lunch at cafe")
    let viewModel = ExpenseDetailViewModel(expenseRepository: mockRepo, expense: expense)
    
    return NavigationStack {
        ExpenseDetailView(viewModel: viewModel)
    }
}
