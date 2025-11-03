//
//  Passes.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import Foundation

enum PassType: String, CaseIterable, Codable {
    case payAsYouGo = "Pay as you go"
    case membership = "Membership"
    case punchCard = "Punch card"
}

struct Pass: Identifiable, Codable {
    var id: UUID
    var mainInformation: MainInformation
    var barcodeData: BarcodeData
    var passType: PassType
    var gymCompanyId: String? // For chain/multi-site passes
    var gymId: String? // For single-gym passes (independent gyms)
    var isActive: Bool
    var isFavourite: Bool
    
    init(mainInformation: MainInformation, barcodeData: BarcodeData, passType: PassType = .membership, gymCompanyId: String? = nil, gymId: String? = nil, isActive: Bool = false, isFavourite: Bool = false) {
        self.id = UUID()
        self.mainInformation = mainInformation
        self.barcodeData = barcodeData
        self.passType = passType
        self.gymCompanyId = gymCompanyId
        self.gymId = gymId
        self.isActive = isActive
        self.isFavourite = isFavourite
    }
    
    var isValid: Bool {
        mainInformation.isValid && barcodeData.isValid
    }
    
    // Helper to check if pass is valid at a specific gym
    func isValidAt(gymId: String, companies: [GymCompany]) -> Bool {
        // Chain pass: check if gym belongs to the company
        if let companyId = self.gymCompanyId,
           let company = companies.first(where: { $0.id == companyId }),
           let gymIds = company.gymIds {
            return gymIds.contains(gymId)
        }
        
        // Single-gym pass: direct match
        if let singleGymId = self.gymId {
            return singleGymId == gymId
        }
        
        return false
    }
    
    // Convenience to check if this is a multi-site pass
    var isMultiSite: Bool {
        gymCompanyId != nil
    }
}

struct MainInformation: Codable {
    var title: String
    var date: Date
    
    init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
    
    var isValid: Bool {
        !title.isEmpty
    }
}

struct BarcodeData: Codable {
    var code: String
    var codeType: String
    
    init(code: String, codeType: String) {
        self.code = code
        self.codeType = codeType
    }
    
    var isValid: Bool {
        !code.isEmpty && !codeType.isEmpty
    }
}


extension Pass: DeletableItem {
    var deletionMessage: String {
        isActive ? "This is your primary pass. Are you sure you want to delete it?" : "Are you sure you want to delete this pass?"
    }
    var requiresConfirmation: Bool {
        true
    }
}
