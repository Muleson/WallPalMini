//
//  Passes.swift
//  GriGriMVP
//
//  Created by Sam Quested on 20/12/2024.
//

import Foundation
import CoreImage.CIFilterBuiltins

struct Pass: Identifiable, Codable {
    var id: UUID
    var mainInformation: MainInformation
    var barcodeData: BarcodeData
    var isActive: Bool
    var isFavourite: Bool
    
    init(mainInformation: MainInformation, barcodeData:BarcodeData, isActive: Bool = false, isFavourite: Bool = false) {
        self.id = UUID()
        self.mainInformation = mainInformation
        self.barcodeData = barcodeData
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
