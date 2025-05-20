// ProgressPhoto.swift
import Foundation

struct ProgressPhoto: Identifiable, Codable, Hashable {
    var id: UUID = UUID()                 // Unique identifier for Firestore + SwiftUI
    var day: Int                          // Healing Day (1, 3, 7, etc.)
    var imageURL: String                  // Firebase Storage image link
    var date: Date                        // When photo was taken or uploaded
    var healingStatus: String? = nil      // Optional AI-generated analysis (e.g. "Improving")
    var notes: String? = nil              // Optional user-entered notes
}
