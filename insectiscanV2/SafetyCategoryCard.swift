//
//  SafetyCategoryCard.swift
//  insectiscanV2
//
//  Created by Jason Grife on 4/30/25.
//

import Foundation
import SwiftUI

struct SafetyCategoryCard: View {
    let category: SafetyCategory

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            Text(category.rawValue)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(category.color)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
