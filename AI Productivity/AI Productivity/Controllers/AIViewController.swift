import UIKit
import AVFoundation
import Speech  // New import for native speech recognition
import Foundation

extension Notification.Name {
    static let calendarTaskAdded = Notification.Name("calendarTaskAdded")
    static let dailyTaskAdded = Notification.Name("dailyTaskAdded")
}

// 1. Update ChatMessage and Sender to conform to Codable.
struct ChatMessage: Codable {
    let sender: Sender
    let text: String
    var isError: Bool = false  // Indicates if the message failed to load correctly
}

enum Sender: String, Codable {
    case ai, user
}

class AIViewController: UIViewController {

    // MARK: - UI Elements
    private var messages: [ChatMessage] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.allowsSelection = false
        return tv
    }()
    
    private let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let inputTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.layer.cornerRadius = 16
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.isScrollEnabled = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let micButton: UIButton = {
        let button = UIButton(type: .system)
        let configImage = UIImage(systemName: "mic.fill")
        button.setImage(configImage, for: .normal)
        button.tintColor = UIColor.systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let recordingIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "Listening..."
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let recordingCancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName:"xmark"), for: .normal)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let sendRecordingButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName:"checkmark"), for: .normal)
        button.tintColor = .systemGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let recordingIndicatorView: UILabel = {
        let label = UILabel()
        label.text = "Recording..."
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Voice Recording Properties
    private var isRecording = false
    private var audioRecorder: AVAudioRecorder?

    // MARK: - Speech Recognition Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        setupInputComponents()
        registerForKeyboardNotifications()
        
        // Load previous conversation memory.
        loadConversation()
        
        // Register the new AI cell.
        tableView.register(AIMessageCell.self, forCellReuseIdentifier: "AIMessageCell")
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus != .authorized {
                print("Speech recognition not authorized.")
            }
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTableTap))
        tableView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Add a bottom inset equal to the input container's height.
        let bottomInset = inputContainerView.bounds.height + view.safeAreaInsets.bottom
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup UI
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.register(AIMessageCell.self, forCellReuseIdentifier: "AIMessageCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupInputComponents() {
        view.addSubview(inputContainerView)
        
        // Pin inputContainerView above the safeArea (above tab bar)
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        inputContainerBottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
        
        // Add subviews
        inputContainerView.addSubview(inputTextView)
        inputContainerView.addSubview(sendButton)
        inputContainerView.addSubview(micButton)
        inputContainerView.addSubview(recordingIndicatorLabel) // still keep old indicator if needed
        // Add new recording controls
        inputContainerView.addSubview(recordingCancelButton)
        inputContainerView.addSubview(sendRecordingButton)
        inputContainerView.addSubview(recordingIndicatorView)
        
        // Existing constraints for sendButton, micButton, inputTextView, recordingIndicatorLabel
        NSLayoutConstraint.activate([
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 50),
            
            micButton.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            micButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 30),
            micButton.heightAnchor.constraint(equalToConstant: 30),
            
            inputTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 8),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextView.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -8),
            
            recordingIndicatorLabel.centerXAnchor.constraint(equalTo: inputContainerView.centerXAnchor),
            recordingIndicatorLabel.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 4)
        ])
        
        // New constraints for recording controls (initially hidden)
        NSLayoutConstraint.activate([
            recordingCancelButton.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 8),
            recordingCancelButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            recordingCancelButton.widthAnchor.constraint(equalToConstant: 30),
            recordingCancelButton.heightAnchor.constraint(equalToConstant: 30),
            
            sendRecordingButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -8),
            sendRecordingButton.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            sendRecordingButton.widthAnchor.constraint(equalToConstant: 30),
            sendRecordingButton.heightAnchor.constraint(equalToConstant: 30),
            
            recordingIndicatorView.centerXAnchor.constraint(equalTo: inputContainerView.centerXAnchor),
            recordingIndicatorView.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor)
        ])
        
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(handleMic), for: .touchUpInside)
        recordingCancelButton.addTarget(self, action: #selector(cancelRecording), for: .touchUpInside)
        sendRecordingButton.addTarget(self, action: #selector(sendRecording), for: .touchUpInside)
    }
    
    // MARK: - Keyboard Notifications
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func handleKeyboardWillShow(notification: Notification) {
        if let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            let keyboardFrame = frameValue.cgRectValue
            inputContainerBottomConstraint.constant = -keyboardFrame.height + view.safeAreaInsets.bottom
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func handleKeyboardWillHide(notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            inputContainerBottomConstraint.constant = 0
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleMic() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc private func handleTableTap() {
        view.endEditing(true)
    }
    
    @objc private func handleSend() {
        guard let text = inputTextView.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Append user message
        let userMessage = ChatMessage(sender: .user, text: text)
        messages.append(userMessage)
        let userIndexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [userIndexPath], with: .automatic)
        
        // Insert a placeholder for the AI response showing "Loading..."
        let placeholderMessage = ChatMessage(sender: .ai, text: "Loading...")
        messages.append(placeholderMessage)
        let placeholderIndex = messages.count - 1
        let placeholderIndexPath = IndexPath(row: placeholderIndex, section: 0)
        tableView.insertRows(at: [placeholderIndexPath], with: .automatic)
        
        scrollToBottom()
        saveConversation()
        
        inputTextView.text = ""
        view.endEditing(true)
        
        // Fetch AI response and update the placeholder cell when ready.
        fetchAIResponse(for: text, placeholderIndex: placeholderIndex)
    }
    
    private func scrollToBottom() {
        if messages.count > 0 {
            let lastIndexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: - Voice Recording Methods
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure audio session for recording
            try audioSession.setCategory(.record, mode: .default, options: [])
            try audioSession.setActive(true)
            
            // Define recording settings for AVAudioRecorder (if needed)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // Hide non–voice input UI elements while recording
            micButton.isHidden = true
            recordingIndicatorLabel.isHidden = true  // hide any old indicator
            recordingCancelButton.isHidden = false
            sendRecordingButton.isHidden = false
            recordingIndicatorView.isHidden = false
            inputTextView.isUserInteractionEnabled = false
            inputTextView.isHidden = true
            sendButton.isHidden = true
            
            // Start native speech recognition
            startSpeechRecognition()
            
        } catch {
            print("Recording failed: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        // Return UI elements to normal state
        animateMicButton(recording: false)
        recordingIndicatorLabel.isHidden = true
        inputTextView.isUserInteractionEnabled = true
        inputTextView.isHidden = false
        sendButton.isHidden = false
    }
    
    private func animateMicButton(recording: Bool) {
        if recording {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           options: [.autoreverse, .repeat],
                           animations: {
                self.micButton.tintColor = .red
                self.micButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            })
        } else {
            micButton.layer.removeAllAnimations()
            micButton.tintColor = .systemBlue
            micButton.transform = .identity
        }
    }
    
    @objc private func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        // Delete any transcribed/entered text.
        inputTextView.text = ""
        // Discard the recording controls and return UI to its normal state.
        hideRecordingControls()
        // Also stop speech recognition if running.
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
    }
    
    @objc private func sendRecording() {
        // Stop recording and hide recording UI controls.
        audioRecorder?.stop()
        isRecording = false
        hideRecordingControls()
        
        // Use native iOS Speech Recognition instead.
        // Stop the audioEngine to complete recognition.
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        // The recognition callback (below) will update inputTextView and optionally auto-send.
    }
    
    // New method to start native speech recognition using SFSpeechRecognizer
    private func startSpeechRecognition() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    print("Speech recognition authorization denied.")
                    return
                }
                do {
                    // If a tap is already installed, remove it.
                    let inputNode = self.audioEngine.inputNode
                    inputNode.removeTap(onBus: 0)
                    
                    self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                    guard let recognitionRequest = self.recognitionRequest else {
                        fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
                    }
                    recognitionRequest.shouldReportPartialResults = true

                    self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                        if let result = result {
                            // Update the text view with the current transcription
                            self.inputTextView.text = result.bestTranscription.formattedString
                            
                            // Optionally, when the result is final, auto-send
                            if result.isFinal {
                                self.handleSend()
                            }
                        }
                        
                        if error != nil {
                            self.audioEngine.stop()
                            inputNode.removeTap(onBus: 0)
                            self.recognitionRequest = nil
                            self.recognitionTask = nil
                        }
                    }
                    
                    let recordingFormat = inputNode.outputFormat(forBus: 0)
                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                        self.recognitionRequest?.append(buffer)
                    }
                    
                    self.audioEngine.prepare()
                    try self.audioEngine.start()
                } catch {
                    print("Error starting speech recognition: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func hideRecordingControls() {
        recordingCancelButton.isHidden = true
        sendRecordingButton.isHidden = true
        recordingIndicatorView.isHidden = true
        micButton.isHidden = false
        inputTextView.isUserInteractionEnabled = true
        
        // Show the text bar and send button again
        inputTextView.isHidden = false
        sendButton.isHidden = false
    }
    
    // MARK: - AI Response Handling
    private func fetchAIResponse(for prompt: String, placeholderIndex: Int? = nil) {
        guard let url = URL(string: "https://models.inference.ai.azure.com/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
        
        let messagePayload: [[String: String]] = [
            ["role": "system", "content": "You are OKSH, an assistant specialized in productivity. Only respond to queries regarding productivity topics, such as calendar events, daily agendas, meetings, studies, work, and related matters. If a query is not productivity-related, respond with 'I can only assist with productivity-related inquiries.'"],
            ["role": "user", "content": prompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messagePayload,
            "stream": false,
            "temperature": 1,
            "max_tokens": 4096,
            "top_p": 1
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize payload")
            return
        }
        request.httpBody = payloadData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("HTTP Error: \(httpResponse.statusCode)")
                if let data = data, let respStr = String(data: data, encoding: .utf8) {
                    print("Response: \(respStr)")
                }
                // If rate limit (429) is reached, update UI accordingly.
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                    DispatchQueue.main.async {
                        let errorMessage = ChatMessage(sender: .ai, text: "Quota exceeded. Please try again later.")
                        if let index = placeholderIndex, index < self.messages.count {
                            self.messages[index] = errorMessage
                            let indexPath = IndexPath(row: index, section: 0)
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                        // Disable user interaction on text input and mic buttons.
                        self.inputTextView.isUserInteractionEnabled = false
                        self.micButton.isEnabled = false
                        self.sendButton.isEnabled = false
                    }
                }
                return
            }
            guard let data = data else {
                print("No data received.")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        let aiMessage = ChatMessage(sender: .ai, text: content)
                        if let index = placeholderIndex, index < self.messages.count {
                            self.messages[index] = aiMessage
                            let indexPath = IndexPath(row: index, section: 0)
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        } else {
                            self.messages.append(aiMessage)
                            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                            self.tableView.insertRows(at: [indexPath], with: .automatic)
                        }
                        self.scrollToBottom()
                        self.saveConversation()
                    }
                } else {
                    print("Invalid JSON structure.")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

// MARK: - TableView DataSource
extension AIViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.sender == .ai {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AIMessageCell", for: indexPath) as? AIMessageCell else {
                return UITableViewCell()
            }
            cell.setFormattedResponse(message.text)
            cell.onCopy = {
                // Copy the AI response text to the clipboard.
                UIPasteboard.general.string = message.text
            }
            cell.onRedo = { [weak self] in
                guard let self = self, indexPath.row > 0 else { return }
                // Use the previous (user) message as the prompt.
                let previousMessage = self.messages[indexPath.row - 1]
                
                // Replace the current AI message with a placeholder.
                self.messages[indexPath.row] = ChatMessage(sender: .ai, text: "Loading...")
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                
                // Fetch new response to update the same placeholder cell.
                self.fetchAIResponse(for: previousMessage.text, placeholderIndex: indexPath.row)
            }
            return cell
        } else {
            // Configure user message cell...
            // (Assuming MessageCell exists and is configured)
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
                return UITableViewCell()
            }
            cell.configure(with: message)
            cell.onRetry = { [weak self] in
                guard let self = self else { return }
                self.fetchAIResponse(for: message.text, placeholderIndex: indexPath.row)
                self.messages[indexPath.row].isError = false
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            return cell
        }
    }
}

// MARK: - Custom Message Cell
class MessageCell: UITableViewCell {
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // New Retry button for error messages
    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    // Closure callback that the parent can set to re-run a message.
    var onRetry: (() -> Void)?
    
    // Keep a reference of the complete message text (for copy action)
    private var fullMessageText: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(retryButton)
        
        // Constrain messageLabel inside bubbleView
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12)
        ])
        
        // Constrain bubbleView with a max width
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
        
        // Constrain Retry button below bubbleView
        NSLayoutConstraint.activate([
            retryButton.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            retryButton.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            retryButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Add a long press gesture to the bubbleView for copy action
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        bubbleView.addGestureRecognizer(longPress)
        
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // New configure method using ChatMessage
    func configure(with message: ChatMessage) {
        fullMessageText = message.text
        messageLabel.text = message.text
        
        if message.sender == .user {
            bubbleView.backgroundColor = UIColor.systemBlue
            messageLabel.textColor = .white
            trailingConstraint.isActive = true
            leadingConstraint.isActive = false
        } else {
            bubbleView.backgroundColor = UIColor.systemGray5
            messageLabel.textColor = .black
            leadingConstraint.isActive = true
            trailingConstraint.isActive = false
        }
        
        // If the message is in error state, add a red border and show the Retry button.
        if message.isError {
            bubbleView.layer.borderColor = UIColor.red.cgColor
            bubbleView.layer.borderWidth = 2
            retryButton.isHidden = false
        } else {
            bubbleView.layer.borderColor = nil
            bubbleView.layer.borderWidth = 0
            retryButton.isHidden = true
        }
    }
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
    
    @objc private func handleLongPress() {
        let menu = UIMenuController.shared
        if !menu.isMenuVisible, let text = fullMessageText {
            becomeFirstResponder()
            let copyItem = UIMenuItem(title: "Copy", action: #selector(copyMessage))
            menu.menuItems = [copyItem]
            menu.setTargetRect(bubbleView.frame, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    @objc private func copyMessage() {
        if let textToCopy = fullMessageText {
            UIPasteboard.general.string = textToCopy
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

// MARK: - Data Extension
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Offline Response Handling
func handleOfflineResponse(_ query: String, completion: @escaping (String) -> Void) {
    let lowercasedQuery = query.lowercased()
    
    // Check for calendar commands
    if lowercasedQuery.contains("calendar") || lowercasedQuery.contains("meeting") {
        // For calendar tasks, we need a title and date.
        // Use your parsing logic; for example, extractTitle could default to "Meeting" if the keyword is found.
        let title = extractTitle(from: query).isEmpty ? "Meeting" : extractTitle(from: query)
        // extractDate should be refined to parse phrases like "tomorrow at 8 PM"; otherwise, it defaults to now.
        let date = extractDate(from: query) ?? defaultCalendarDate()
        let isRecurring = lowercasedQuery.contains("recurring")
        
        let newCalendarTask = CalendarTask(
            title: title,
            date: date,
            recurrence: isRecurring ? .daily : nil   // Adjust recurrence if needed.
        )
        NotificationCenter.default.post(name: .calendarTaskAdded, object: newCalendarTask)
        completion("Got it! I've added the \(title) to your in-app calendar.")
    
    // Check for daily agenda commands (e.g. "agenda" or "daily task")
    } else if lowercasedQuery.contains("agenda") || lowercasedQuery.contains("daily task") {
        // For daily agenda items, we need: title, an icon (deduced from categories), a start time, and duration.
        let title = extractTitle(from: query)
        let icon = deduceIcon(from: query) ?? "work"   // Deduces icon from keywords; default to "work" if you wish.
        let time = extractTime(from: query) ?? Date()
        let duration = extractDuration(from: query) ?? 15  // Default to 15 minutes.
        
        let newDailyTask = ExtendedTask(
            id: UUID(),
            title: title,
            description: "",
            time: formattedTime(from: time),
            priority: "Medium",           // For agenda items, priority may be less relevant.
            category: icon,
            dueDate: time,
            duration: duration,
            isCompleted: false,
            reminderDate: nil,
            notificationId: nil,
            recurrence: "None",
            cancelledOccurrences: []
        )
        NotificationCenter.default.post(name: .dailyTaskAdded, object: newDailyTask)
        completion("Daily agenda task added: \(title)")
    
    // Otherwise, assume a to-do list command.
    } else if lowercasedQuery.contains("add task") {
        // For to-do list items, we need: title, category, priority and due date.
        let title = extractTitle(from: query)
        let category = deduceCategory(from: query) ?? "Personal"  // Defaults to Personal if none specified.
        let priority = deducePriority(from: query) ?? "Medium"      // Default priority.
        let dueDate = extractDueDate(from: query) ?? defaultTodoDueDate()
        
        let newTask = Task(
            title: title,
            description: "",
            time: formattedTime(from: dueDate),
            priority: priority,
            category: category,
            dueDate: dueDate,
            isCompleted: false,
            reminderDate: nil,
            notificationId: nil
        )
        NotificationCenter.default.post(name: .taskAdded, object: newTask)
        completion("To-do task added: \(title)")
    } else {
        completion("Command not recognized.")
    }
}

// MARK: - Helper Methods (Implement these as needed)

/// Extracts a task title from the query.
private func extractTitle(from query: String) -> String {
    // Placeholder: implement your own NLP or regex parsing.
    // For example, remove command phrases and trim the remaining text.
    return query.replacingOccurrences(of: "add task", with: "")
                .replacingOccurrences(of: "calendar", with: "")
                .replacingOccurrences(of: "agenda", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Extracts a Date from the query string.
private func extractDate(from query: String) -> Date? {
    // Placeholder: implement date extraction logic.
    return nil
}

/// Default calendar date, for example, use parsed date or default to now.
private func defaultCalendarDate() -> Date {
    return Date()  // Customize if needed.
}

/// Deduces an icon from keywords. Categories: ["food", "health", "mail", "exam", "shopping", "exercise", "work"]
private func deduceIcon(from query: String) -> String? {
    let categories = ["food", "health", "mail", "exam", "shopping", "exercise", "work"]
    for category in categories {
        if query.lowercased().contains(category) {
            return category
        }
    }
    return nil
}

/// Deduce the category for a to-do task.
private func deduceCategory(from query: String) -> String? {
    if query.contains("work") { return "Work" }
    if query.contains("study") { return "Study" }
    // Default will be Personal if none match.
    return nil
}

/// Deduce the priority for a to-do task.
private func deducePriority(from query: String) -> String? {
    if query.contains("high") { return "High" }
    if query.contains("low") { return "Low" }
    return nil  // Return nil so that the default "Medium" is used.
}

/// Extracts a time from the query.
private func extractTime(from query: String) -> Date? {
    // Placeholder: use NLP/date parsing library or regex.
    return nil
}

/// Extracts a duration (in minutes) from the query.
private func extractDuration(from query: String) -> Int? {
    // Placeholder: use regex to look for values like "30 minutes" or "1h".
    return nil
}

/// Extracts a due date for the to-do list task.
private func extractDueDate(from query: String) -> Date? {
    // Placeholder: use NLP/date parsing to extract a due date.
    return nil
}

/// Provides a default to-do task due date: today at 11:59pm.
private func defaultTodoDueDate() -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = 23
    components.minute = 59
    return Calendar.current.date(from: components) ?? Date()
}

/// Formats a Date to a time string.
private func formattedTime(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
}

// MARK: - Conversation Persistence
extension AIViewController {
    private func saveConversation() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: "conversationMemory")
        }
    }
    
    private func loadConversation() {
        if let data = UserDefaults.standard.data(forKey: "conversationMemory"),
           let savedMessages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = savedMessages
            tableView.reloadData()
            scrollToBottom()
        }
    }
}
