//import Foundation
//import Network
//
//class ChatbotManager {
//    static let shared = ChatbotManager()
//    
//    private let apiKey = "YOUR_OPENAI_API_KEY" // Replace with your API key
//    private let endpoint = "https://api.openai.com/v1/chat/completions"
//    private let monitor = NWPathMonitor()
//    private var isOnline = false
//
//    private init() {
//        monitor.pathUpdateHandler = { path in
//            self.isOnline = path.status == .satisfied
//        }
//        let queue = DispatchQueue(label: "Monitor")
//        monitor.start(queue: queue)
//    }
//    
//    func processUserQuery(_ query: String, completion: @escaping (String) -> Void) {
//        if isOnline {
//            sendRequestToGPT(query, completion: completion)
//        } else {
//            handleOfflineResponse(query, completion: completion)
//        }
//    }
//    
//    private func sendRequestToGPT(_ query: String, completion: @escaping (String) -> Void) {
//        let requestBody: [String: Any] = [
//            "model": "gpt-4",
//            "messages": [["role": "user", "content": query]],
//            "temperature": 0.7
//        ]
//        
//        guard let url = URL(string: endpoint),
//              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
//            completion("Error creating request.")
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = jsonData
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data,
//                  let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                  let choices = jsonResponse["choices"] as? [[String: Any]],
//                  let message = choices.first?["message"] as? [String: Any],
//                  let content = message["content"] as? String else {
//                completion("Failed to get response.")
//                return
//            }
//            completion(content)
//        }.resume()
//    }
//
//    private func handleOfflineResponse(_ query: String, completion: @escaping (String) -> Void) {
//        let lowercasedQuery = query.lowercased()
//        
//        if lowercasedQuery.contains("add task") {
//            let taskTitle = query.replacingOccurrences(of: "add task", with: "").trimmingCharacters(in: .whitespaces)
//            let priority = "Medium" // Default priority
//            TaskManager.shared.addTask(title: taskTitle, priority: priority)
//            completion("Task added: \(taskTitle) [Priority: \(priority)]")
//        } else if lowercasedQuery.contains("remove task") {
//            let taskTitle = query.replacingOccurrences(of: "remove task", with: "").trimmingCharacters(in: .whitespaces)
//            TaskManager.shared.removeTask(title: taskTitle)
//            completion("Task removed: \(taskTitle)")
//        } else {
//            completion("AI features are limited offline.")
//        }
//    }
//
//}
