import Foundation

struct UserPreferences: Codable {
    var userName: String
    var preferences: [String: String] // e.g. ["theme": "dark", "language": "en"]
}