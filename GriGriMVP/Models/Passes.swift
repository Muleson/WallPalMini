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
    var gymId: String?
    var isActive: Bool
    var isFavourite: Bool
    
    init(mainInformation: MainInformation, barcodeData:BarcodeData, passType: PassType = .membership, gymId: String? = nil, isActive: Bool = false, isFavourite: Bool = false) {
        self.id = UUID()
        self.mainInformation = mainInformation
        self.barcodeData = barcodeData
        self.passType = passType
        self.gymId = gymId
        self.isActive = isActive
        self.isFavourite = isFavourite
        
        var isValid: Bool {
            mainInformation.isValid && barcodeData.isValid
        }
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
