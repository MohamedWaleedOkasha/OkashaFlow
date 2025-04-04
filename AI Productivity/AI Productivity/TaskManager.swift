import Foundation

class TaskManager {
    static let shared = TaskManager()
    
    private var tasks: [(title: String, priority: String)] = []
    
    private init() {}
    
    func addTask(title: String, priority: String) {
        tasks.append((title, priority))
    }
    
    func removeTask(title: String) {
        tasks.removeAll { $0.title == title }
    }
    
    func getTasks() -> [(String, String)] {
        return tasks
    }
}
