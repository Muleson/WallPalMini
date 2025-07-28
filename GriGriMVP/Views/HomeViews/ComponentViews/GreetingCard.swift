//
//  GreetingCard.swift
//  GriGriMVP
//
//  Created by Sam Quested on 26/07/2025.
//


import SwiftUI

struct GreetingSection: View {
    let userName: String?
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning,"
        case 12..<17:
            return "Good Afternoon,"
        case 17..<22:
            return "Good Evening,"
        default:
            return "Good Night,"
        }
    }
    
    private var motivationalText: String {
        let motivationalPhrases = [
            "Perfect time to send that project!",
            "Ready for your next climb?",
            "Time to crush those routes!",
            "Let's make today count!",
            "Your next send awaits!"
        ]
        
        return motivationalPhrases.randomElement() ?? "Perfect time to send that project!"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(greetingText)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundColor(AppTheme.appPrimary)
                
                if let name = userName, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundColor(AppTheme.appTextPrimary)
                }
            }
            
            Text(motivationalText)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.appTextLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

#Preview {
    GreetingSection(userName: "Sam")
        .background(Color(AppTheme.appBackgroundBG))
}
