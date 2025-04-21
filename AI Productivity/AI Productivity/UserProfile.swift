import Foundation

struct UserProfile: Codable {
    let name: String
    let age: Int?
    let profileImageURL: String?
    let userId: String
    
    init(name: String, age: Int? = nil, profileImageURL: String? = nil, userId: String) {
        self.name = name
        self.age = age
        self.profileImageURL = profileImageURL
        self.userId = userId
    }
} 