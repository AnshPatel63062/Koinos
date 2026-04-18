//
//  KoinosRepository.swift
//  Koinos
//
//  Created by Ansh Patel on 17/04/26.
//

import Foundation

protocol KoinosRepository {
    func getInfo() async throws -> [String: Any]
}
