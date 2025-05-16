import Foundation

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var age: Int?
    var gender: String?
    var skinColor: String?
    var allergies: [String]?
    var medicalConditions: [String]?
    var country: String?
}
    