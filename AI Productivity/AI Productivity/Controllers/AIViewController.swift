import UIKit
import AVFoundation
import Speech  // New import for native speech recognition

struct ChatMessage {
    let sender: Sender
    let text: String
}

enum Sender {
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
        
        // Request speech recognition authorization
        SFSpeechRecognizer.requestAuthorization { authStatus in
            if authStatus != .authorized {
                print("Speech recognition not authorized.")
            }
        }
        
        // Dismiss the keyboard when tapping on the table view.
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
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),  // goes behind the tab bar overlay
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
        scrollToBottom()
        
        // Clear input and dismiss keyboard
        inputTextView.text = ""
        view.endEditing(true)
        
        // Fetch AI response from the API (non-streaming)
        fetchAIResponse(for: text)
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
        // Discard the recording and return UI to its normal state.
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
    private func fetchAIResponse(for prompt: String) {
        guard let url = URL(string: "https://models.inference.ai.azure.com/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Use the new API key prefixed with "Bearer"
        request.addValue("Bearer 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", forHTTPHeaderField: "Authorization")
        
        let messagePayload: [[String: String]] = [
            ["role": "system", "content": "You are OKSH, an assistant in a productivity app with functions such as a todo list, calendar, and daily agenda. Your goal is to help users manage their tasks and schedule efficiently."],
            ["role": "user", "content": prompt]
        ]
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": messagePayload,
            "stream": false, // disable streaming
            "temperature": 1,
            "max_tokens": 4096,
            "top_p": 1
        ]
        
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Failed to serialize payload")
            return
        }
        request.httpBody = payloadData
        
        // Use a simple dataTask that returns all data at once.
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received.")
                return
            }
            do {
                // Parse the JSON response
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        let aiMessage = ChatMessage(sender: .ai, text: content)
                        self.messages.append(aiMessage)
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                        self.scrollToBottom()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as? MessageCell else {
            return UITableViewCell()
        }
        let message = messages[indexPath.row]
        cell.configure(with: message.text, isUser: message.sender == .user)
        return cell
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
    
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        
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
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 250)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with message: String, isUser: Bool) {
        messageLabel.text = message
        
        if isUser {
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
