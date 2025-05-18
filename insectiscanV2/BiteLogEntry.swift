// BiteLogEntry.swift (clean version without ProgressPhoto declaration)
import Foundation

struct BiteLogEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var imageURL: String
    var notes: String
    var diagnosisSummary: String
    var severity: Int?
    var autoSaved: Bool? = false
    var locationDescription: String? = nil
    var progressImages: [ProgressPhoto]? = []
}
