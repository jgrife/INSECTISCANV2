//
//  DiagnosisResultView.swift
//  insectiscanV2
//
//  Created by Jason Grife on 4/30/25.
//



// MARK: - 6. DiagnosisResultView.swift
import SwiftUI
struct DiagnosisResultView: View {
    let resultTitle: String
    let resultSummary: String
    let recommendations: [String]
    let followUpQuestions: [String]

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resultTitle)
                            .font(.title.bold())
                            .foregroundColor(Color("PrimaryColor"))

                        Text(resultSummary)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommended Actions")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryColor"))

                        ForEach(recommendations, id: \.self) { item in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(Color("AccentColor"))
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Follow-Up Questions")
                            .font(.headline)
                            .foregroundColor(Color("PrimaryColor"))

                        ForEach(followUpQuestions, id: \.self) { question in
                            HStack(alignment: .top) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.orange)
                                Text(question)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Diagnosis Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color("PrimaryColor"))
                }
            }
        }
    }
} 

// Example usage (can be replaced with real GPT result at runtime):
/*
DiagnosisResultView(
    resultTitle: "Mosquito Bite - Low Risk",
    resultSummary: "Localized swelling, redness, and itching. No spreading signs detected.",
    recommendations: [
        "Clean the area with mild soap and water",
        "Apply a cold compress",
        "Use antihistamine cream if needed",
        "Avoid scratching to prevent infection"
    ],
    followUpQuestions: [
        "Has the swelling increased since yesterday?",
        "Are you feeling any fever or chills?",
        "Have you had similar bites before?"
    ]
)
*/
