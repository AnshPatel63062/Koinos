//
//  KoinosViewModel.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import Foundation
import Observation

@Observable
class KoinosViewModel {
    private let repository: KoinosRepository
    
    var infoData: [String: Any] = [:]
    var isLoading = false
    var errorMessage: String?
    
    init(repository: KoinosRepository) {
        self.repository = repository
    }
    
    @MainActor
    func fetchInfo() async {
        isLoading = true
        errorMessage = nil
        
        do {
            infoData = try await repository.getInfo()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
