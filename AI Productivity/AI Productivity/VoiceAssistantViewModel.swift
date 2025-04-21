// import Foundation
// import AVFoundation
// import Speech

// class VoiceAssistantViewModel: ObservableObject {
//     @Published var isRecording = false
//     @Published var transcribedText = ""
//     @Published var aiResponse = ""
//     @Published var showError = false
//     @Published var errorMessage = ""
    
//     private var audioEngine = AVAudioEngine()
//     private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//     private var recognitionTask: SFSpeechRecognitionTask?
//     private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
//     private let audioSession = AVAudioSession.sharedInstance()
//     private var audioRecorder: AVAudioRecorder?
//     private let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.m4a")
    
//     init() {
//         requestPermissions()
//     }
    
//     private func requestPermissions() {
//         SFSpeechRecognizer.requestAuthorization { [weak self] status in
//             DispatchQueue.main.async {
//                 switch status {
//                 case .authorized:
//                     break
//                 default:
//                     self?.showError = true
//                     self?.errorMessage = "Speech recognition not authorized"
//                 }
//             }
//         }
//     }
    
//     func toggleRecording() {
//         if isRecording {
//             stopRecording()
//         } else {
//             startRecording()
//         }
//     }
    
//     private func startRecording() {
//         guard let recognizer = speechRecognizer, recognizer.isAvailable else {
//             showError = true
//             errorMessage = "Speech recognition is not available"
//             return
//         }
        
//         do {
//             try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//             try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
//             let settings: [String: Any] = [
//                 AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
//                 AVSampleRateKey: 44100.0,
//                 AVNumberOfChannelsKey: 1,
//                 AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
//             ]
            
//             audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
//             audioRecorder?.record()
//             isRecording = true
            
//         } catch {
//             showError = true
//             errorMessage = "Failed to start recording: \(error.localizedDescription)"
//         }
//     }
    
//     private func stopRecording() {
//         audioRecorder?.stop()
//         isRecording = false
//         transcribeAudio()
//     }
    
//     private func transcribeAudio() {
//         guard let audioData = try? Data(contentsOf: audioFilename) else {
//             showError = true
//             errorMessage = "Could not read audio file"
//             return
//         }
        
//         let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
//         var request = URLRequest(url: url)
//         request.httpMethod = "POST"
//         request.addValue("Bearer \(Config.openAIKey)", forHTTPHeaderField: "Authorization")
        
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
//             DispatchQueue.main.async {
//                 if let error = error {
//                     self?.showError = true
//                     self?.errorMessage = "Transcription error: \(error.localizedDescription)"
//                     return
//                 }
                
//                 if let data = data,
//                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                    let transcription = json["text"] as? String {
//                     self?.transcribedText = transcription
//                     self?.processWithGPT(transcription)
//                 }
//             }
//         }.resume()
//     }
    
//     private func processWithGPT(_ text: String) {
//         let url = URL(string: "https://api.openai.com/v1/chat/completions")!
//         var request = URLRequest(url: url)
//         request.httpMethod = "POST"
//         request.addValue("Bearer \(Config.openAIKey)", forHTTPHeaderField: "Authorization")
//         request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
//         let systemPrompt = """
//         You are a helpful voice assistant. Process the user's voice command and respond appropriately.
//         For task management commands:
//         - If adding a task, extract the task details and confirm
//         - If scheduling a reminder, confirm the time and date
//         - If asking for productivity advice, provide concise, actionable tips
//         Keep responses brief and clear.
//         """
        
//         let body: [String: Any] = [
//             "model": "gpt-4",
//             "messages": [
//                 ["role": "system", "content": systemPrompt],
//                 ["role": "user", "content": text]
//             ],
//             "temperature": 0.7
//         ]
        
//         request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
//         URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//             DispatchQueue.main.async {
//                 if let error = error {
//                     self?.showError = true
//                     self?.errorMessage = "GPT error: \(error.localizedDescription)"
//                     return
//                 }
                
//                 if let data = data,
//                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                    let choices = json["choices"] as? [[String: Any]],
//                    let message = choices.first?["message"] as? [String: Any],
//                    let content = message["content"] as? String {
//                     self?.aiResponse = content
//                 }
//             }
//         }.resume()
//     }
// } 