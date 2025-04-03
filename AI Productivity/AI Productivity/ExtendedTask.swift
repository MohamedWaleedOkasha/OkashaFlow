import Foundation

struct ExtendedTask: Codable {
    let title: String
    let description: String
    let time: String
    let priority: String
    let category: String
    let dueDate: Date
    let duration: Int
    var isCompleted: Bool
    let reminderDate: Date?
    let notificationId: String?
    let recurrence: String   // e.g. "None", "Daily", "Weekly", "Monthly"
    var cancelledOccurrences: [Date]  // new property

    init(title: String,
         description: String,
         time: String,
         priority: String,
         category: String,
         dueDate: Date,
         duration: Int,
         isCompleted: Bool = false,
         reminderDate: Date? = nil,
         notificationId: String? = nil,
         recurrence: String = "None",
         cancelledOccurrences: [Date] = []) {
        self.title = title
        self.description = description
        self.time = time
        self.priority = priority
        self.category = category
        self.dueDate = dueDate
        self.duration = duration
        self.isCompleted = isCompleted
        self.reminderDate = reminderDate
        self.notificationId = notificationId
        self.recurrence = recurrence
        self.cancelledOccurrences = cancelledOccurrences
    }
}