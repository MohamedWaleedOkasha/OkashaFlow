// import UIKit
// import Speech
// import AVFoundation

// class VoiceAssistantViewController: UIViewController {
    
//     // MARK: - Properties
//     private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
//     private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
//     private var recognitionTask: SFSpeechRecognitionTask?
//     private let audioEngine = AVAudioEngine()
    
//     // MARK: - UI Components
//     private let micButton: UIButton = {
//         let button = UIButton(type: .system)
//         button.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
//         button.tintColor = .systemBlue
//         button.contentVerticalAlignment = .fill
//         button.contentHorizontalAlignment = .fill
//         button.translatesAutoresizingMaskIntoConstraints = false
//         return button
//     }()
    
//     private let statusLabel: UILabel = {
//         let label = UILabel()
//         label.text = "Tap mic to start"
//         label.textAlignment = .center
//         label.font = .systemFont(ofSize: 16)
//         label.translatesAutoresizingMaskIntoConstraints = false
//         return label
//     }()
    
//     private let responseTextView: UITextView = {
//         let textView = UITextView()
//         textView.isEditable = false
//         textView.font = .systemFont(ofSize: 16)
//         textView.layer.borderColor = UIColor.systemGray4.cgColor
//         textView.layer.borderWidth = 1
//         textView.layer.cornerRadius = 8
//         textView.translatesAutoresizingMaskIntoConstraints = false
//         return textView
//     }()
    
//     // MARK: - Lifecycle
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         setupUI()
//         requestPermissions()
//     }
    
//     // MARK: - UI Setup
//     private func setupUI() {
//         view.backgroundColor = .systemBackground
//         title = "Voice Assistant"
        
//         view.addSubview(micButton)
//         view.addSubview(statusLabel)
//         view.addSubview(responseTextView)
        
//         NSLayoutConstraint.activate([
//             micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//             micButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
//             micButton.widthAnchor.constraint(equalToConstant: 60),
//             micButton.heightAnchor.constraint(equalToConstant: 60),
            
//             statusLabel.topAnchor.constraint(equalTo: micButton.bottomAnchor, constant: 20),
//             statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//             statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
//             responseTextView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
//             responseTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//             responseTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//             responseTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
//         ])
        
//         micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
//     }
    
//     // MARK: - Permissions
//     private func requestPermissions() {
//         SFSpeechRecognizer.requestAuthorization { [weak self] status in
//             DispatchQueue.main.async {
//                 switch status {
//                 case .authorized:
//                     self?.micButton.isEnabled = true
//                 case .denied, .restricted, .notDetermined:
//                     self?.micButton.isEnabled = false
//                     self?.statusLabel.text = "Speech recognition not authorized"
//                 @unknown default:
//                     break
//                 }
//             }
//         }
//     }
    
//     // MARK: - Voice Recognition
//     @objc private func micButtonTapped() {
//         if audioEngine.isRunning {
//             stopRecording()
//         } else {
//             startRecording()
//         }
//     }
    
//     private func startRecording() {
//         if recognitionTask != nil {
//             recognitionTask?.cancel()
//             recognitionTask = nil
//         }
        
//         let audioSession = AVAudioSession.sharedInstance()
//         do {
//             try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
//             try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
//         } catch {
//             print("Audio session setup failed: \(error)")
//             return
//         }
        
//         recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
//         let inputNode = audioEngine.inputNode
//         guard let recognitionRequest = recognitionRequest else {
//             return
//         }
        
//         recognitionRequest.shouldReportPartialResults = true
        
//         recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
//             guard let self = self else { return }
            
//             if let result = result {
//                 let transcribedText = result.bestTranscription.formattedString
//                 self.statusLabel.text = transcribedText
                
//                 if result.isFinal {
//                     self.processVoiceCommand(transcribedText)
//                 }
//             }
            
//             if error != nil {
//                 self.stopRecording()
//             }
//         }
        
//         let recordingFormat = inputNode.outputFormat(forBus: 0)
//         inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//             recognitionRequest.append(buffer)
//         }
        
//         audioEngine.prepare()
        
//         do {
//             try audioEngine.start()
//             micButton.tintColor = .systemRed
//             statusLabel.text = "Listening..."
//         } catch {
//             print("Audio engine start failed: \(error)")
//         }
//     }
    
//     private func stopRecording() {
//         audioEngine.stop()
//         audioEngine.inputNode.removeTap(onBus: 0)
//         recognitionRequest?.endAudio()
//         micButton.tintColor = .systemBlue
//         statusLabel.text = "Tap mic to start"
//     }
    
//     // MARK: - Command Processing
//     private func processVoiceCommand(_ command: String) {
//         let lowercasedCommand = command.lowercased()
        
//         // Process the command and generate appropriate response
//         let response: String
        
//         if lowercasedCommand.contains("add task") {
//             // Extract task details
//             if let task = lowercasedCommand.components(separatedBy: "add task").last?.trimmingCharacters(in: .whitespaces) {
//                 // Here you would integrate with your task management system
//                 response = "Added task: \(task)"
//             } else {
//                 response = "Could not understand the task. Please try again."
//             }
//         } else if lowercasedCommand.contains("schedule") || lowercasedCommand.contains("reminder") {
//             response = "I'll help you schedule that. Please use the calendar feature to set the exact time."
//         } else if lowercasedCommand.contains("productivity") || lowercasedCommand.contains("advice") {
//             // Get AI-powered productivity advice
//             getProductivityAdvice(for: command) { [weak self] advice in
//                 DispatchQueue.main.async {
//                     self?.responseTextView.text = advice
//                 }
//             }
//             return
//         } else {
//             response = "I heard: \(command)\nTry saying 'add task', 'schedule reminder', or 'productivity advice'"
//         }
        
//         responseTextView.text = response
//     }
    
//     private func getProductivityAdvice(for query: String, completion: @escaping (String) -> Void) {
//         let chatbot = AIChatbotViewController()
//         chatbot.fetchGPTResponse(for: "Give me productivity advice about: \(query)") { response in
//             completion(response)
//         }
//     }
// } 