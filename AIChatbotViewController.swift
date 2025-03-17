//import UIKit
//
//class AIChatbotViewController: UIViewController {
//    
//    private let textField: UITextField = {
//        let field = UITextField()
//        field.placeholder = "Ask AI something..."
//        field.borderStyle = .roundedRect
//        return field
//    }()
//    
//    private let sendButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Send", for: .normal)
//        button.addTarget(self, action: #selector(sendQuery), for: .touchUpInside)
//        return button
//    }()
//    
//    private let responseTextView: UITextView = {
//        let textView = UITextView()
//        textView.isEditable = false
//        textView.font = UIFont.systemFont(ofSize: 16)
//        return textView
//    }()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        setupLayout()
//    }
//    
//    private func setupLayout() {
//        view.addSubview(textField)
//        view.addSubview(sendButton)
//        view.addSubview(responseTextView)
//        
//        textField.translatesAutoresizingMaskIntoConstraints = false
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        responseTextView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
//            
//            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
//            
//            responseTextView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
//            responseTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            responseTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            responseTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
//        ])
//    }
//    
//    @objc private func sendQuery() {
//        guard let query = textField.text, !query.isEmpty else { return }
//        responseTextView.text = "Thinking..."
//        
//        ChatbotManager.shared.processUserQuery(query) { [weak self] response in
//            DispatchQueue.main.async {
//                self?.responseTextView.text = response
//            }
//        }
//    }
//}
//import Foundation
//
//class AIChatbotViewController {
//    
//    private let apiKey = "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"
//    
//    func fetchGPTResponse(for message: String, completion: @escaping (String) -> Void) {
//        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: Any] = [
//            "model": "gpt-4",
//            "messages": [["role": "user", "content": message]],
//            "temperature": 0.7
//        ]
//        
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                completion("Error: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let choices = json["choices"] as? [[String: Any]],
//                   let text = choices.first?["message"] as? [String: Any],
//                   let content = text["content"] as? String {
//                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
//                } else {
//                    completion("Error: Invalid response from API")
//                }
//            } catch {
//                completion("Error: \(error.localizedDescription)")
//            }
//        }.resume()
//    }
////}
//import Foundation
//
//class AIChatbotViewController {
//    func fetchGPTResponse(for message: String, completion: @escaping (String) -> Void) {
//        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
//            print("🚨 Error: Missing API Key in Info.plist")
//            return
//        }
//        
//        let url = URL(string: "https://api.forefront.ai/v1/chat/completions")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: Any] = [
//            "model": "gpt-3.5-turbo",
//            "messages": [["role": "user", "content": message]],
//            "temperature": 0.5
//        ]
//
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: body)
//        } catch {
//            print("🚨 JSON Encoding Error: \(error.localizedDescription)")
//            return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("❌ Network Error: \(error.localizedDescription)")
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse {
//                print("ℹ️ API Status Code: \(httpResponse.statusCode)")
//            }
//
//            guard let data = data else {
//                print("❌ No Data Received")
//                return
//            }
//
//            if let responseString = String(data: data, encoding: .utf8) {
//                print("🔍 API Response: \(responseString)")
//            }
//        }.resume()
//    }
//}
import UIKit
import Foundation
import AVFAudio

struct APIError: Codable {
    struct ErrorDetail: Codable {
        let message: String
    }
    let error: ErrorDetail
}

struct ForefrontResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

class AIChatbotViewController: UIViewController {
    // MARK: - Properties
    private let audioEngine = AVAudioEngine()
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.m4a")
    
    // MARK: - UI Components
    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Ask AI something..."
        field.borderStyle = .roundedRect
        return field
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.addTarget(self, action: #selector(sendQuery), for: .touchUpInside)
        return button
    }()
    
    private let responseTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 16)
        return textView
    }()
    
    private let micButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle & Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        setupAudioSession()
    }
    
    private func setupLayout() {
        view.addSubview(textField)
        view.addSubview(sendButton)
        view.addSubview(responseTextView)
        view.addSubview(micButton)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        micButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            
            responseTextView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            responseTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            responseTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            responseTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            micButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            micButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            micButton.widthAnchor.constraint(equalToConstant: 44),
            micButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Voice Recording
    @objc private func micButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            micButton.tintColor = .systemRed
        } catch {
            print("Recording failed: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        micButton.tintColor = .systemBlue
        
        // Process the recording
        transcribeAudio()
    }
    
    // MARK: - Whisper Integration
    private func transcribeAudio() {
        guard let audioData = try? Data(contentsOf: audioFilename) else {
            print("Could not read audio file")
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
            print("Missing API Key")
            return
        }
        
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Transcription error: \(error)")
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let transcription = json["text"] as? String {
                DispatchQueue.main.async {
                    self?.textField.text = transcription
                    self?.sendQuery() // Automatically send the transcribed text to GPT
                }
            }
        }.resume()
    }
    
    @objc private func sendQuery() {
        guard let query = textField.text, !query.isEmpty else { return }
        responseTextView.text = "Thinking..."
        
        fetchGPTResponse(for: query) { [weak self] response in
            DispatchQueue.main.async {
                self?.responseTextView.text = response
            }
        }
    }
    
    func fetchGPTResponse(for message: String, completion: @escaping (String) -> Void) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
            print("🚨 Error: Missing API Key in Info.plist")
            handleOfflineResponse(query: message, completion: completion)
            return
        }
        
        let url = URL(string: "https://api.forefront.ai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": message]],
            "temperature": 0.7
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("🚨 JSON Encoding Error: \(error.localizedDescription)")
            handleOfflineResponse(query: message, completion: completion)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network Error: \(error.localizedDescription)")
                self.handleOfflineResponse(query: message, completion: completion)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("ℹ️ API Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 400 {
                    // If we get a 400 and no data, fall back.
                    guard let data = data, !data.isEmpty else {
                        self.handleOfflineResponse(query: message, completion: completion)
                        return
                    }
                    
                    // Try parsing error if data exists.
                    if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                        print("🔍 API Error: \(apiError.error.message)")
                    }
                    self.handleOfflineResponse(query: message, completion: completion)
                    return
                }
            }
            
            guard let data = data, !data.isEmpty else {
                print("❌ No Data Received")
                self.handleOfflineResponse(query: message, completion: completion)
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(ForefrontResponse.self, from: data)
                let content = decodedResponse.choices.first?.message.content ?? "No response"
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                print("🚨 Parsing Error: \(error.localizedDescription)")
                self.handleOfflineResponse(query: message, completion: completion)
            }
        }.resume()
    }
    
    // MARK: - Fallback Offline NLP Response
    private func handleOfflineResponse(query: String, completion: @escaping (String) -> Void) {
        let lowercasedQuery = query.lowercased()
        if lowercasedQuery.contains("add task") {
            completion("Offline Mode: To add a task, please use the manual input.")
        } else if lowercasedQuery.contains("remove task") {
            completion("Offline Mode: To remove a task, please use the manual input.")
        } else {
            completion("Offline Mode: AI features are limited when not connected.")
        }
    }
}



