// import UIKit

// class ChatbotViewController: UIViewController {
    
//     private let chatTextView: UITextView = {
//         let textView = UITextView()
//         textView.isEditable = false
//         textView.font = UIFont.systemFont(ofSize: 16)
//         textView.backgroundColor = .systemBackground
//         textView.layer.cornerRadius = 12
//         textView.layer.borderWidth = 1
//         textView.layer.borderColor = UIColor.systemGray5.cgColor
//         textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
//         return textView
//     }()
    
//     private let inputField: UITextField = {
//         let field = UITextField()
//         field.borderStyle = .roundedRect
//         field.placeholder = "Type a message..."
//         field.backgroundColor = .systemBackground
//         field.layer.cornerRadius = 20
//         field.layer.borderWidth = 1
//         field.layer.borderColor = UIColor.systemGray5.cgColor
//         field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
//         field.leftViewMode = .always
//         return field
//     }()
    
//     private let sendButton: UIButton = {
//         let button = UIButton(type: .system)
//         button.setTitle("Send", for: .normal)
//         button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//         button.backgroundColor = .systemBlue
//         button.setTitleColor(.white, for: .normal)
//         button.layer.cornerRadius = 20
//         button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
//         return button
//     }()
    
//     private let aiChatbot = AIChatbotViewController()
//     private var messages: [(isUser: Bool, text: String)] = []
    
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         view.backgroundColor = .systemGray6
//         title = "AI Assistant"
//         setupUI()
//         setupKeyboardHandling()
//     }
    
//     private func setupUI() {
//         chatTextView.translatesAutoresizingMaskIntoConstraints = false
//         inputField.translatesAutoresizingMaskIntoConstraints = false
//         sendButton.translatesAutoresizingMaskIntoConstraints = false
        
//         view.addSubview(chatTextView)
//         view.addSubview(inputField)
//         view.addSubview(sendButton)
        
//         NSLayoutConstraint.activate([
//             chatTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//             chatTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//             chatTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//             chatTextView.bottomAnchor.constraint(equalTo: inputField.topAnchor, constant: -16),
            
//             inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//             inputField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//             inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
//             inputField.heightAnchor.constraint(equalToConstant: 40),
            
//             sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//             sendButton.bottomAnchor.constraint(equalTo: inputField.bottomAnchor),
//             sendButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
//         ])
        
//         sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
//         inputField.delegate = self
//     }
    
//     private func setupKeyboardHandling() {
//         NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
//         NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
//     }
    
//     @objc private func keyboardWillShow(notification: NSNotification) {
//         guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
//         UIView.animate(withDuration: 0.3) {
//             self.view.transform = CGAffineTransform(translationX: 0, y: -keyboardFrame.height)
//         }
//     }
    
//     @objc private func keyboardWillHide(notification: NSNotification) {
//         UIView.animate(withDuration: 0.3) {
//             self.view.transform = .identity
//         }
//     }
    
//     @objc private func sendMessage() {
//         guard let userInput = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
//               !userInput.isEmpty else { return }
        
//         // Add user message
//         messages.append((isUser: true, text: userInput))
//         updateChatDisplay()
        
//         // Clear input
//         inputField.text = ""
        
//         // Show typing indicator
//         messages.append((isUser: false, text: "Thinking..."))
//         updateChatDisplay()
        
//         // Get AI response
//         aiChatbot.fetchGPTResponse(for: userInput) { [weak self] response in
//             DispatchQueue.main.async {
//                 // Remove typing indicator
//                 self?.messages.removeLast()
                
//                 // Add AI response
//                 self?.messages.append((isUser: false, text: response))
//                 self?.updateChatDisplay()
//             }
//         }
//     }
    
//     private func updateChatDisplay() {
//         var displayText = ""
//         for (isUser, text) in messages {
//             displayText += isUser ? "You: " : "AI: "
//             displayText += text + "\n\n"
//         }
//         chatTextView.text = displayText
        
//         // Scroll to bottom
//         let bottom = NSRange(location: displayText.count - 1, length: 1)
//         chatTextView.scrollRangeToVisible(bottom)
//     }
// }

// extension ChatbotViewController: UITextFieldDelegate {
//     func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//         sendMessage()
//         return true
//     }
// }
