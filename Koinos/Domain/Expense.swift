//
//  Expense.swift
//  Koinos
//
//  Created by Ansh Patel on 18/04/26.
//

import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id: String
    var amount: Double
    var category: String
    var date: Date
    var description: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case category
        case date
        case description
    }
    
    // Category enum for predefined categories
    enum Category: String, CaseIterable {
        case food = "Food"
        case transportation = "Transportation"
        case entertainment = "Entertainment"
        case utilities = "Utilities"
        case healthcare = "Healthcare"
        case shopping = "Shopping"
        case other = "Other"
        
        var systemImage: String {
            switch self {
            case .food:
                return "fork.knife"
            case .transportation:
                return "car.fill"
            case .entertainment:
                return "film.fill"
            case .utilities:
                return "lightbulb.fill"
            case .healthcare:
                return "heart.fill"
            case .shopping:
                return "bag.fill"
            case .other:
                return "circle.fill"
            }
        }
    }
}
