//
//  SafetyDetailView.swift
//  insectiscanV2
//
//  Created by Jason Grife on 4/30/25.
//

import Foundation
import SwiftUI

struct SafetyDetailView: View {
    let category: SafetyCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(category.rawValue) Safety")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("PrimaryColor"))

                Text("Here's how to stay safe in areas where you might encounter \(category.rawValue.lowercased()):")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                ForEach(0..<5) { index in
                    Text("• Sample tip #\(index + 1) for \(category.rawValue.lowercased()).")
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
