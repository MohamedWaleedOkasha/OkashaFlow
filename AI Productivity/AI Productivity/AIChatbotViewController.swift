// import UIKit
// import Foundation
// import AVFAudio

// struct APIError: Codable {
//     struct ErrorDetail: Codable {
//         let message: String
//     }
//     let error: ErrorDetail
// }

// struct ForefrontResponse: Codable {
//     struct Choice: Codable {
//         struct Message: Codable {
//             let content: String
//         }
//         let message: Message
//     }
//     let choices: [Choice]
// }

// class AIChatbotViewController: UIViewController {
//     // MARK: - Properties
//     private let audioEngine = AVAudioEngine()
//     private var audioRecorder: AVAudioRecorder?
//     private var isRecording = false
//     private let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.m4a")
    
//     // MARK: - UI Components
//     private let textField: UITextField = {
//         let field = UITextField()
//         field.placeholder = "Ask AI something..."
//         field.borderStyle = .roundedRect
//         return field
//     }()
    
//     private let sendButton: UIButton = {
//         let button = UIButton(type: .system)
//         button.setTitle("Send", for: .normal)
//         button.addTarget(self, action: #selector(sendQuery), for: .touchUpInside)
//         return button
//     }()
    
//     private let responseTextView: UITextView = {
//         let textView = UITextView()
//         textView.isEditable = false
//         textView.font = UIFont.systemFont(ofSize: 16)
//         return textView
//     }()
    
//     private let micButton: UIButton = {
//         let button = UIButton(type: .system)
//         button.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
//         button.tintColor = .systemBlue
//         button.contentVerticalAlignment = .fill
//         button.contentHorizontalAlignment = .fill
//         button.translatesAutoresizingMaskIntoConstraints = false
//         return button
//     }()
    
//     // MARK: - Lifecycle & Setup
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         view.backgroundColor = .white
//         setupLayout()
//         setupAudioSession()
//     }
    
//     private func setupLayout() {
//         view.addSubview(textField)
//         view.addSubview(sendButton)
//         view.addSubview(responseTextView)
//         view.addSubview(micButton)
        
//         textField.translatesAutoresizingMaskIntoConstraints = false
//         sendButton.translatesAutoresizingMaskIntoConstraints = false
//         responseTextView.translatesAutoresizingMaskIntoConstraints = false
//         micButton.translatesAutoresizingMaskIntoConstraints = false
        
//         NSLayoutConstraint.activate([
//             textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//             textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//             textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
//             sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//             sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            
//             responseTextView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
//             responseTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//             responseTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//             responseTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
//             micButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
//             micButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
//             micButton.widthAnchor.constraint(equalToConstant: 44),
//             micButton.heightAnchor.constraint(equalToConstant: 44)
//         ])
        
//         micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
//     }
    
//     private func setupAudioSession() {
//         let audioSession = AVAudioSession.sharedInstance()
//         do {
//             try audioSession.setCategory(.playAndRecord, mode: .default)
//             try audioSession.setActive(true)
//         } catch {
//             print("Audio session setup failed: \(error)")
//         }
//     }
    
//     // MARK: - Voice Recording
//     @objc private func micButtonTapped() {
//         if isRecording {
//             stopRecording()
//         } else {
//             startRecording()
//         }
//     }
    
//     private func startRecording() {
//         let settings: [String: Any] = [
//             AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//             AVSampleRateKey: 44100.0,
//             AVNumberOfChannelsKey: 1,
//             AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//         ]
        
//         do {
//             audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
//             audioRecorder?.record()
//             isRecording = true
//             micButton.tintColor = .systemRed
//         } catch {
//             print("Recording failed: \(error)")
//         }
//     }
    
//     private func stopRecording() {
//         audioRecorder?.stop()
//         isRecording = false
//         micButton.tintColor = .systemBlue
        
//         // Process the recording
//         transcribeAudio()
//     }
    
//     // MARK: - Whisper Integration
//     private func transcribeAudio() {
//         guard let audioData = try? Data(contentsOf: audioFilename) else {
//             print("Could not read audio file")
//             return
//         }
        
//         let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
//         var request = URLRequest(url: url)
//         request.httpMethod = "POST"
        
//         guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
//             print("Missing API Key")
//             return
//         }
        
//         request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
//         let boundary = UUID().uuidString
//         request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
//         var body = Data()
        
//         // Add model parameter
//         body.append("--\(boundary)\r\n".data(using: .utf8)!)
//         body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
//         body.append("whisper-1\r\n".data(using: .utf8)!)
        
//         // Add file data
//         body.append("--\(boundary)\r\n".data(using: .utf8)!)
//         body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
//         body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
//         body.append(audioData)
//         body.append("\r\n".data(using: .utf8)!)
        
//         body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
//         request.httpBody = body
        
//         URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//             if let error = error {
//                 print("Transcription error: \(error)")
//                 return
//             }
            
//             if let data = data,
//                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                let transcription = json["text"] as? String {
//                 DispatchQueue.main.async {
//                     self?.textField.text = transcription
//                     self?.sendQuery() // Automatically send the transcribed text to GPT
//                 }
//             }
//         }.resume()
//     }
    
//     @objc private func sendQuery() {
//         guard let query = textField.text, !query.isEmpty else { return }
//         responseTextView.text = "Thinking..."
        
//         fetchGPTResponse(for: query) { [weak self] response in
//             DispatchQueue.main.async {
//                 self?.responseTextView.text = response
//             }
//         }
//     }
    
//     func fetchGPTResponse(for message: String, completion: @escaping (String) -> Void) {
//         guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
//             print("🚨 Error: Missing API Key in Info.plist")
//             self.handleOfflineResponse(query: message, completion: completion)
//             return
//         }
        
//         // Use OpenAI's API endpoint (or your chosen endpoint)
//         let url = URL(string: "https://api.openai.com/v1/chat/completions")!
//         var request = URLRequest(url: url)
//         request.httpMethod = "POST"
//         request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//         request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
//         let body: [String: Any] = [
//             "model": "gpt-3.5-turbo", // or "gpt-4" if available
//             "messages": [["role": "user", "content": message]],
//             "temperature": 0.7
//         ]
        
//         do {
//             request.httpBody = try JSONSerialization.data(withJSONObject: body)
//         } catch {
//             print("🚨 JSON Encoding Error: \(error.localizedDescription)")
//             self.handleOfflineResponse(query: message, completion: completion)
//             return
//         }
        
//         URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//             if let error = error {
//                 print("❌ Network Error: \(error.localizedDescription)")
//                 self?.handleOfflineResponse(query: message, completion: completion)
//                 return
//             }
            
//             if let httpResponse = response as? HTTPURLResponse {
//                 print("ℹ️ API Status Code: \(httpResponse.statusCode)")
//                 // If status code indicates an error, fall back offline.
//                 if httpResponse.statusCode != 200 {
//                     self?.handleOfflineResponse(query: message, completion: completion)
//                     return
//                 }
//             }
            
//             guard let data = data, !data.isEmpty else {
//                 print("❌ No Data Received")
//                 self?.handleOfflineResponse(query: message, completion: completion)
//                 return
//             }
            
//             do {
//                 let decodedResponse = try JSONDecoder().decode(ForefrontResponse.self, from: data)
//                 let content = decodedResponse.choices.first?.message.content ?? "No response"
//                 completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
//             } catch {
//                 print("🚨 Parsing Error: \(error.localizedDescription)")
//                 self?.handleOfflineResponse(query: message, completion: completion)
//             }
//         }.resume()
//     }
    
//     // MARK: - Fallback Offline NLP Response
//     private func handleOfflineResponse(query: String, completion: @escaping (String) -> Void) {
//         let lowercasedQuery = query.lowercased()
//         var offlineResponse = ""
        
//         // Here we simulate offline processing using simple keyword checks (inspired by Apple’s NLP features)
//         if lowercasedQuery.contains("add task") {
//             // Extract task details (this can be expanded using NSLinguisticTagger for more robust extraction)
//             let taskDetail = lowercasedQuery.replacingOccurrences(of: "add task", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//             // Simulate adding a task programatically
//             // TaskManager.shared.addTask(title: taskDetail, priority: "Medium") // Uncomment if using a task manager
//             offlineResponse = "Offline Mode: Task '\(taskDetail)' added."
//         } else if lowercasedQuery.contains("remove task") {
//             let taskDetail = lowercasedQuery.replacingOccurrences(of: "remove task", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//             // Simulate removal of the task here
//             // TaskManager.shared.removeTask(title: taskDetail)
//             offlineResponse = "Offline Mode: Task '\(taskDetail)' removed."
//         } else if lowercasedQuery.contains("productivity") || lowercasedQuery.contains("advice") {
//             offlineResponse = "Offline Mode: Remember to take regular breaks and stay hydrated for better productivity."
//         } else {
//             offlineResponse = "Offline Mode: AI features are limited when not connected. Please try again later."
//         }
        
//         completion(offlineResponse)
//     }
// }



