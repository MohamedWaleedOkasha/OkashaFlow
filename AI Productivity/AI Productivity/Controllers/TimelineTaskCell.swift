import UIKit

class TimelineTaskCell: UITableViewCell {

    // Dynamic bar container for the split (completed/incomplete) bar.
    private let dynamicBarContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Completed portion (black).
    private let completedBar: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Incomplete portion (gray).
    private let incompleteBar: UIView = {
        let view = UIView()
        view.backgroundColor = .gray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Timeline indicator circle.
    private let timelineIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Icon view for task category.
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.systemBlue
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Title label.
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Time label.
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Info container for task details.
    private let infoContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Task completion button.
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        button.setImage(UIImage(systemName: "circle", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.systemGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // Closure to handle done button tap.
    var doneButtonAction: (() -> Void)?

    // Stored completion fraction for dynamic bar.
    private var completionFraction: CGFloat = 1.0

    // MARK: - Configuration

    /// Configures the cell with a task and optional previous/next tasks to compute the dynamic progress.
    func configure(with task: ExtendedTask, previousTask: ExtendedTask?, nextTask: ExtendedTask?) {
        // Set title with strikethrough if completed.
        if task.isCompleted {
            let attributes: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.systemGray
            ]
            titleLabel.attributedText = NSAttributedString(string: task.title, attributes: attributes)
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = task.title
        }
        
        timeLabel.text = task.time
        iconImageView.image = getIcon(for: task.category)
        infoContainer.backgroundColor = getColor(for: task.category)
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        let doneImageName = task.isCompleted ? "checkmark.circle.fill" : "circle"
        doneButton.setImage(UIImage(systemName: doneImageName, withConfiguration: config), for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        // Calculate dynamic progress fraction if previous and next tasks exist.
        if let prev = previousTask, let next = nextTask {
            let totalInterval = next.dueDate.timeIntervalSince(prev.dueDate)
            if totalInterval > 0 {
                let currentInterval = task.dueDate.timeIntervalSince(prev.dueDate)
                completionFraction = CGFloat(currentInterval / totalInterval)
            } else {
                completionFraction = 1.0
            }
        } else {
            completionFraction = 1.0
        }
        
        dynamicBarContainer.subviews.forEach { $0.removeFromSuperview() }
        dynamicBarContainer.addSubview(completedBar)
        dynamicBarContainer.addSubview(incompleteBar)
        
        setupLayout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        // Adjust dynamic bar subviews based on computed fraction.
        let containerHeight = dynamicBarContainer.bounds.height
        let completedHeight = containerHeight * completionFraction
        completedBar.frame = CGRect(x: 0, y: 0, width: dynamicBarContainer.bounds.width, height: completedHeight)
        incompleteBar.frame = CGRect(x: 0, y: completedHeight, width: dynamicBarContainer.bounds.width, height: containerHeight - completedHeight)
    }

    private func setupLayout() {
        // Remove all subviews from contentView.
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add dynamic bar container.
        contentView.addSubview(dynamicBarContainer)
        NSLayoutConstraint.activate([
            dynamicBarContainer.widthAnchor.constraint(equalToConstant: 2),
            dynamicBarContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            dynamicBarContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            dynamicBarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32)
        ])

        // Add timeline indicator.
        contentView.addSubview(timelineIndicator)
        NSLayoutConstraint.activate([
            timelineIndicator.centerXAnchor.constraint(equalTo: dynamicBarContainer.centerXAnchor),
            timelineIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timelineIndicator.widthAnchor.constraint(equalToConstant: 16),
            timelineIndicator.heightAnchor.constraint(equalToConstant: 16)
        ])

        // Add done button.
        contentView.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            doneButton.widthAnchor.constraint(equalToConstant: 28),
            doneButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        // Add info container.
        contentView.addSubview(infoContainer)
        NSLayoutConstraint.activate([
            infoContainer.leadingAnchor.constraint(equalTo: dynamicBarContainer.trailingAnchor, constant: 16),
            infoContainer.trailingAnchor.constraint(equalTo: doneButton.leadingAnchor, constant: -8),
            infoContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoContainer.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Add subviews to info container.
        infoContainer.addSubview(iconImageView)
        infoContainer.addSubview(titleLabel)
        infoContainer.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: infoContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor, constant: -12),
            
            timeLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            timeLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func doneButtonTapped() {
        doneButtonAction?()
    }

    // MARK: - Helpers

    private func getIcon(for category: String) -> UIImage? {
        switch category.lowercased() {
        case "food":
            return UIImage(systemName: "fork.knife")
        case "health":
            return UIImage(systemName: "cross.case.fill")
        case "mail":
            return UIImage(systemName: "envelope.fill")
        case "exam":
            return UIImage(systemName: "graduationcap.fill")
        case "shopping":
            return UIImage(systemName: "bag.fill")
        case "exercise":
            return UIImage(systemName: "figure.walk")
        case "work":
            return UIImage(systemName: "desktopcomputer")
        default:
            return UIImage(systemName: "checkmark.circle")
        }
    }

    private func getColor(for category: String) -> UIColor {
        switch category.lowercased() {
        case "food":
            return UIColor.systemTeal.withAlphaComponent(0.2)
        case "health":
            return UIColor.systemRed.withAlphaComponent(0.2)
        case "mail":
            return UIColor.systemIndigo.withAlphaComponent(0.2)
        case "exam":
            return UIColor.systemPurple.withAlphaComponent(0.2)
        case "shopping":
            return UIColor.systemPink.withAlphaComponent(0.2)
        case "exercise":
            return UIColor.systemYellow.withAlphaComponent(0.2)
        case "work":
            return UIColor.systemGreen.withAlphaComponent(0.2)
        default:
            return UIColor.systemGray.withAlphaComponent(0.2)
        }
    }

    // MARK: - Initializer

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // Disable default selection highlight.
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}