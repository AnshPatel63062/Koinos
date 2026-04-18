//
//  KoinosService.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import Foundation

class KoinosService: KoinosRepository {
    private let client: MCPClient
    
    init(client: MCPClient) {
        self.client = client
    }
    
    func getInfo() async throws -> [String: Any] {
        let result = try await client.callTool(
            name: "get_info",
            arguments: [:]
        )
        
        guard let textContent = result else {
            throw NSError(
                domain: "KoinosService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response from get_info"]
            )
        }
        
        if let jsonData = textContent.data(using: .utf8),
           let decoded = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            return decoded
        }
        
        return ["raw": textContent]
    }
}
