import Foundation

// Models for Exam Scheduler
struct Chapter: Codable {
    let name: String
    var isCompleted: Bool = false
}

struct Subject: Codable {
    let name: String
    let examDate: Date
    var chapters: [Chapter]
}

// Create a ChapterAssignment type to make encoding/decoding easier
struct ChapterAssignment: Codable {
    let subjectName: String
    var chapter: Chapter
}

struct StudySession: Codable {
    let date: Date
    var chapters: [ChapterAssignment]
    let isBreakDay: Bool
}

enum Priority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    
    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum TimeSlot: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
}

struct ExamSchedule {
    let examDate: Date
    let subjects: [Subject]
    let dailyStudyHours: Int
    var studySessions: [StudySession]
    let breakDays: [Date]
    let revisionDays: Int
}

struct StudyTask: Codable {
    let id: UUID
    let title: String
    var isCompleted: Bool
    
    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct StudyDay: Codable {
    let date: Date
    var tasks: [StudyTask]
} 