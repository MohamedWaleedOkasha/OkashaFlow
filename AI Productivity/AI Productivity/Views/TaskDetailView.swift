import UIKit

class TaskDetailView: UIView {

    // New label to display the task's day.
    let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    // Label to display time.
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    // Label to display length.
    let lengthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .black
        return label
    }()
    
    // Existing notes label.
    let notesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    // Delete task button.
    let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Task", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 5
        return button
    }()
    
    // New edit task button.
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Task", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 5
        return button
    }()
    
    // New close button.
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Callbacks for actions.
    var deleteAction: (() -> Void)?
    var editAction: (() -> Void)?
    var closeAction: (() -> Void)?

    
    
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
        addSubview(editButton)
        addSubview(deleteButton)
        addSubview(closeButton) // Add the close button

        // Set up targets.
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)

        // Disable autoresizing mask.
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        lengthLabel.translatesAutoresizingMaskIntoConstraints = false
        notesLabel.translatesAutoresizingMaskIntoConstraints = false
        editButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        // Layout constraints.
        NSLayoutConstraint.activate([
            // Close button at the top right.
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Day label at the top (below close button if needed).
            dayLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dayLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Time label below day label.
            timeLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 8),
            timeLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Length label below time label.
            lengthLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            lengthLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            lengthLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Notes label below length label.
            notesLabel.topAnchor.constraint(equalTo: lengthLabel.bottomAnchor, constant: 8),
            notesLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            notesLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            
            // Edit button below notes.
            editButton.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 16),
            editButton.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 120),
            editButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Delete button aligned next to Edit.
            deleteButton.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 16),
            deleteButton.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 120),
            deleteButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Bottom constraint.
            deleteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func handleDelete() {
        deleteAction?()
    }
    
    @objc private func handleEdit() {
        editAction?()
    }
    
    @objc private func handleClose() {
        closeAction?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
