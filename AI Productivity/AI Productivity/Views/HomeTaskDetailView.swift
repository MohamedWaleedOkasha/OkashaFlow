import UIKit

class HomeTaskDetailView: UIView {
    
    // MARK: - UI Components
    
    let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    let lengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    let notesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    // Scrollable area for subtasks.
    private let subtasksScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    // Stack view for subtasks.
    private let subtasksStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Callbacks
    var closeAction: (() -> Void)?
    var updateSubtasksState: (([Bool]) -> Void)?
    
    // Constraint for subtasksScrollView height.
    private var subtasksHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties for Subtask State
    private var task: Task?
    // This array tracks each subtask’s checked (true) or unchecked (false) state.
    private var subtasksChecked: [Bool] = []
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        
        // Add subviews.
        addSubview(dayLabel)
        addSubview(timeLabel)
        addSubview(lengthLabel)
        addSubview(notesLabel)
        addSubview(subtasksScrollView)
        addSubview(closeButton)
        
        // Add stack view to scroll view.
        subtasksScrollView.addSubview(subtasksStackView)
        
        // Disable autoresizing mask.
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        lengthLabel.translatesAutoresizingMaskIntoConstraints = false
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Layout constraints.
        NSLayoutConstraint.activate([
            // Close button.
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Day label.
            dayLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dayLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Time label.
            timeLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Length label.
            lengthLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            lengthLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            lengthLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Notes label.
            notesLabel.topAnchor.constraint(equalTo: lengthLabel.bottomAnchor, constant: 8),
            notesLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            notesLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Subtasks scroll view.
            subtasksScrollView.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            subtasksScrollView.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            subtasksScrollView.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Stack view within scroll view.
            subtasksStackView.topAnchor.constraint(equalTo: subtasksScrollView.topAnchor),
            subtasksStackView.leadingAnchor.constraint(equalTo: subtasksScrollView.leadingAnchor),
            subtasksStackView.trailingAnchor.constraint(equalTo: subtasksScrollView.trailingAnchor),
            subtasksStackView.bottomAnchor.constraint(equalTo: subtasksScrollView.bottomAnchor),
            subtasksStackView.widthAnchor.constraint(equalTo: subtasksScrollView.widthAnchor),
            
            // Bottom constraint for scroll view.
            subtasksScrollView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
        
        // Height constraint for subtasksScrollView.
        subtasksHeightConstraint = subtasksScrollView.heightAnchor.constraint(equalToConstant: 100)
        subtasksHeightConstraint.isActive = true
        
        // Close button: when tapped, save state and dismiss.
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleClose() {
        // Save the current checked state before closing.
        updateSubtasksState?(subtasksChecked)
        closeAction?()
    }
    
    @objc private func subtaskCheckboxTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < subtasksChecked.count else { return }
        // Toggle the check state.
        subtasksChecked[index].toggle()
        let newImageName = subtasksChecked[index] ? "checkmark.square.fill" : "square"
        sender.setImage(UIImage(systemName: newImageName), for: .normal)
    }
    
    // MARK: - Configure Method
    func configure(with task: Task) {
        self.task = task
        dayLabel.text = "Due: \(task.dueDate)"
        timeLabel.text = "Time: \(task.time)"
        lengthLabel.text = "Priority: \(task.priority)"
        notesLabel.text = task.description
        
        // Clear previous subtask views.
        subtasksStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Load saved state; if not available, initialize as unchecked.
        if let savedState = task.subtasksChecked, savedState.count == task.subtasks.count {
            subtasksChecked = savedState
        } else {
            subtasksChecked = Array(repeating: false, count: task.subtasks.count)
        }
        
        // If there are no subtasks, collapse the scroll view.
        if task.subtasks.isEmpty {
            subtasksHeightConstraint.constant = 0
        } else {
            subtasksHeightConstraint.constant = 100
            for (index, subtask) in task.subtasks.enumerated() {
                let isChecked = subtasksChecked[index]
                let subtaskView = createSubtaskView(text: subtask, isChecked: isChecked, tag: index)
                subtasksStackView.addArrangedSubview(subtaskView)
            }
        }
        layoutIfNeeded()
    }
    
    // Helper to create a subtask view.
    private func createSubtaskView(text: String, isChecked: Bool, tag: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center
        
        let checkboxButton = UIButton(type: .system)
        let imageName = isChecked ? "checkmark.square.fill" : "square"
        checkboxButton.setImage(UIImage(systemName: imageName), for: .normal)
        checkboxButton.tintColor = .systemBlue
        checkboxButton.tag = tag
        checkboxButton.addTarget(self, action: #selector(subtaskCheckboxTapped(_:)), for: .touchUpInside)
        checkboxButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkboxButton.widthAnchor.constraint(equalToConstant: 20),
            checkboxButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 1
        
        container.addArrangedSubview(checkboxButton)
        container.addArrangedSubview(label)
        
        return container
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}