//
//  TopSafetyTipRow.swift
//  insectiscanV2
//
//  Created by Jason Grife on 4/30/25.
//

import Foundation
import SwiftUI

struct TopSafetyTipRow: View {
    let iconName: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color("AccentColor"))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryColor"))
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
