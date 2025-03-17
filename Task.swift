import Foundation

struct Task: Codable {
    let title: String
    let description: String
    let time: String
    let priority: String
    let category: String
    let dueDate: Date
    var isCompleted: Bool
    let reminderDate: Date?
    let notificationId: String?
    
    init(title: String, description: String, time: String, priority: String, category: String, dueDate: Date, isCompleted: Bool = false, reminderDate: Date? = nil, notificationId: String? = nil) {
        self.title = title
        self.description = description
        self.time = time
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.reminderDate = reminderDate
        self.notificationId = notificationId
    }
}

