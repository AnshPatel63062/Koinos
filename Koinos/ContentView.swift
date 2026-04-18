//
//  ContentView.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import SwiftUI

struct ContentView: View {
    var viewModel: KoinosViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.circle")
                        .imageScale(.large)
                        .foregroundStyle(.red)
                    Text("Error: \(error)")
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .imageScale(.large)
                        .foregroundStyle(.green)
                    Text("Info Data")
                        .font(.headline)
                    ForEach(Array(viewModel.infoData.keys.sorted()), id: \.self) { key in
                        VStack(alignment: .leading) {
                            Text(key)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(describing: viewModel.infoData[key] ?? "N/A"))
                                .font(.body)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await viewModel.fetchInfo()
                }
            }) {
                Text("Fetch Info")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
    }
}

#Preview {
    let mcpClient = MCPClient()
    let repository: KoinosRepository = KoinosService(client: mcpClient)
    let viewModel = KoinosViewModel(repository: repository)
    return ContentView(viewModel: viewModel)
}
