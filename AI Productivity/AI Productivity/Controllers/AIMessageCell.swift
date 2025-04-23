import UIKit

class AIMessageCell: UITableViewCell {
    let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Stack view to hold the copy and redo buttons.
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8  // reduced spacing for smaller icons
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Copy button with SF Symbol "doc.on.clipboard". Icons are made smaller via imageEdgeInsets.
    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "doc.on.clipboard")
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Redo button with SF Symbol "arrow.clockwise". Icons are made smaller via imageEdgeInsets.
    private let redoButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "arrow.clockwise")
        button.setImage(image, for: .normal)
        button.tintColor = .systemBlue
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Callbacks for button actions.
    var onCopy: (() -> Void)?
    var onRedo: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(messageLabel)
        contentView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(copyButton)
        buttonStackView.addArrangedSubview(redoButton)
        
        // Constrain messageLabel at the top.
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Place buttonStackView below the message label.
            buttonStackView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        copyButton.addTarget(self, action: #selector(handleCopy), for: .touchUpInside)
        redoButton.addTarget(self, action: #selector(handleRedo), for: .touchUpInside)
    }
    
    /// This method accepts a text string with simple markdown-like formatting
    /// where "###" at the start of a line makes a header and **text** makes bold text.
    func setFormattedResponse(_ text: String) {
        messageLabel.attributedText = formatResponse(text)
    }
    
    /// Converts basic markdown to an attributed string.
    private func formatResponse(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attributed.length)
        // Set default attributes
        attributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: fullRange)
        
        // Process header markers "###". For simplicity, assume a header line starts with "### ".
        let headerPattern = "^(###)\\s+(.*)$"
        if let regex = try? NSRegularExpression(pattern: headerPattern, options: [.anchorsMatchLines]) {
            let matches = regex.matches(in: attributed.string, options: [], range: fullRange)
            for match in matches {
                if match.numberOfRanges == 3 {
                    let headerRange = match.range(at: 2)
                    attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 20), range: headerRange)
                }
            }
        }
        
        // Process bold markers "**text**".
        let boldPattern = "\\*\\*(.*?)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: boldPattern, options: []) {
            let matches = regex.matches(in: attributed.string, options: [], range: fullRange)
            // Loop backwards to avoid range shift.
            for match in matches.reversed() {
                if match.numberOfRanges == 2 {
                    let boldTextRange = match.range(at: 1)
                    let boldText = attributed.attributedSubstring(from: boldTextRange)
                    let replacement = NSMutableAttributedString(attributedString: boldText)
                    replacement.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: NSRange(location: 0, length: replacement.length))
                    // Replace the entire marker range.
                    attributed.replaceCharacters(in: match.range, with: replacement)
                }
            }
        }
        return attributed
    }
    
    @objc private func handleCopy() {
        onCopy?()
        // Change the copy icon to checkmark for 4 seconds
        let checkImage = UIImage(systemName: "checkmark")
        self.copyButton.setImage(checkImage, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self = self else { return }
            let originalImage = UIImage(systemName: "doc.on.clipboard")
            self.copyButton.setImage(originalImage, for: .normal)
        }
    }
    
    @objc private func handleRedo() {
        onRedo?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
