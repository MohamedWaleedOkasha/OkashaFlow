import UIKit

protocol NewTaskViewControllerDelegate: AnyObject {
    func didCreateNewTask(_ task: ExtendedTask)
    func didEditTask(_ task: ExtendedTask)
}

class NewTaskViewController: UIViewController {
    
    // MARK: - UI Components
    
    // Header view with blue background and "New Task" label.
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "New Task"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Cancel button in the header (styled as an X)
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✕", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // Container view for title and icon selection.
    private let titleContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Enlarged title text field.
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Task Title"
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // Larger icon segmented control.
    private let iconSegmentedControl: UISegmentedControl = {
        let items = [
            UIImage(systemName: "fork.knife"),
            UIImage(systemName: "cross.case.fill"),
            UIImage(systemName: "envelope.fill"),
            UIImage(systemName: "graduationcap.fill"),
            UIImage(systemName: "bag.fill"),
            UIImage(systemName: "figure.walk"),
            UIImage(systemName: "desktopcomputer")
        ]
        let sc = UISegmentedControl(items: items.compactMap { $0 })
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 20)], for: .normal)
        sc.apportionsSegmentWidthsByContent = true // Ensure segments are sized to content.
        return sc
    }()
    
    // "When?" label.
    private let whenLabel: UILabel = {
        let label = UILabel()
        label.text = "When?"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Centered time picker.
    private let timePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    // Text field for notes.
    private let notesTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Notes (optional)"
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 18)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // "How Long?" label.
    private let howLongLabel: UILabel = {
        let label = UILabel()
        label.text = "How Long?"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let durationSegmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["15m", "30m", "1h", "Custom"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    // Inline custom duration picker remains (if needed inline, otherwise you can remove it as well).
//    private let customDurationPicker: UIDatePicker = {
//        let picker = UIDatePicker()
//        picker.datePickerMode = .countDownTimer
//        picker.translatesAutoresizingMaskIntoConstraints = false
//        return picker
//    }()
//    
    // Floating create button.
    private let createButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Create Task", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        btn.backgroundColor = UIColor.systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    // The selected date passed from DailyTaskManagerViewController.
    var initialDate: Date?
    
    // New property for editing mode.
    var editingTask: ExtendedTask?
    
    // Custom overlay container.
    private let customDurationOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    // Content view that appears at the bottom.
    private let customDurationContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Close button ("x") for the overlay.
    private let customDurationCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("✕", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // (Reuse your customDurationPicker here.)
    private let customDurationPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    // We'll keep a reference to the bottom constraint for animation.
    private var customDurationBottomConstraint: NSLayoutConstraint!
    
    // Add a new property for recurrence segmented control.
    private let recurrenceSegmentedControl: UISegmentedControl = {
        let items = ["None", "Daily", "Weekly", "Monthly"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    // MARK: - Delegate
    weak var delegate: NewTaskViewControllerDelegate?
    
    // MARK: - Lifecycle
    // override func viewDidLoad() {
    //     super.viewDidLoad()
    //     view.backgroundColor = .systemBackground
    //     setupUI()
        
    //     durationSegmentedControl.addTarget(self, action: #selector(durationChanged(_:)), for: .valueChanged)
    //     createButton.addTarget(self, action: #selector(createTask), for: .touchUpInside)
    //     cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
    //     customDurationCloseButton.addTarget(self, action: #selector(hideCustomDurationOverlay), for: .touchUpInside)
    // }
    override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupUI()

    durationSegmentedControl.addTarget(self, action: #selector(durationChanged(_:)), for: .valueChanged)
    createButton.addTarget(self, action: #selector(createTask), for: .touchUpInside)
    cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    customDurationCloseButton.addTarget(self, action: #selector(hideCustomDurationOverlay), for: .touchUpInside)
    
    // If editing an existing task, update UI accordingly.
    if let task = editingTask {
        headerLabel.text = "Edit Task"
        createButton.setTitle("Edit Task", for: .normal)
        titleTextField.text = task.title
        notesTextField.text = task.description
        timePicker.date = task.dueDate
        
        // Configure duration segmented control.
        let duration = task.duration
        if duration == 15 {
            durationSegmentedControl.selectedSegmentIndex = 0
        } else if duration == 30 {
            durationSegmentedControl.selectedSegmentIndex = 1
        } else if duration == 60 {
            durationSegmentedControl.selectedSegmentIndex = 2
        } else {
            durationSegmentedControl.selectedSegmentIndex = 3
            customDurationPicker.countDownDuration = TimeInterval(duration * 60)
        }
        
        // Configure icon segmented control based on task category.
        let categories = ["food", "health", "mail", "exam", "shopping", "exercise", "work"]
        if let index = categories.firstIndex(of: task.category) {
            iconSegmentedControl.selectedSegmentIndex = index
        }
    }
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    view.addGestureRecognizer(tapGesture)
}
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // --- Header View ---
        view.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Add headerLabel and cancelButton with positions switched.
        headerView.addSubview(headerLabel)
        headerView.addSubview(cancelButton)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // "New Task" now on the left.
            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // "✕" button now on the right.
            cancelButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 44),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // --- Main Content Stack View ---
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Task Title Field.
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentStackView.addArrangedSubview(titleTextField)
        
        // Icon Segmented Control under the task title.
        iconSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        iconSegmentedControl.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentStackView.addArrangedSubview(iconSegmentedControl)
        
        // "When?" label.
        whenLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(whenLabel)
        
        // Time Picker.
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        timePicker.heightAnchor.constraint(equalToConstant: 150).isActive = true
        contentStackView.addArrangedSubview(timePicker)
        
        // "How Long?" label.
        howLongLabel.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(howLongLabel)
        
        // Duration Segmented Control.
        durationSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        durationSegmentedControl.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentStackView.addArrangedSubview(durationSegmentedControl)
        
        // "Any Details?" Label.
        let detailsLabel: UILabel = {
            let label = UILabel()
            label.text = "Any Details?"
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        contentStackView.addArrangedSubview(detailsLabel)
        
        // Notes Text Field.
        notesTextField.translatesAutoresizingMaskIntoConstraints = false
        notesTextField.heightAnchor.constraint(equalToConstant: 80).isActive = true
        contentStackView.addArrangedSubview(notesTextField)
        
        // --- Recurrence Segmented Control ---
        recurrenceSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        recurrenceSegmentedControl.heightAnchor.constraint(equalToConstant: 40).isActive = true
        contentStackView.addArrangedSubview(recurrenceSegmentedControl)
        
        // --- Floating Create Task Button ---
        view.addSubview(createButton)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createButton.widthAnchor.constraint(equalToConstant: 200),  // Increased width
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // --- Custom Duration Overlay (unchanged) ---
        view.addSubview(customDurationOverlay)
        NSLayoutConstraint.activate([
            customDurationOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            customDurationOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customDurationOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customDurationOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        customDurationOverlay.addSubview(customDurationContentView)
        customDurationContentView.translatesAutoresizingMaskIntoConstraints = false
        customDurationBottomConstraint = customDurationContentView.bottomAnchor.constraint(equalTo: customDurationOverlay.bottomAnchor, constant: 400)
        NSLayoutConstraint.activate([
            customDurationContentView.leadingAnchor.constraint(equalTo: customDurationOverlay.leadingAnchor, constant: 20),
            customDurationContentView.trailingAnchor.constraint(equalTo: customDurationOverlay.trailingAnchor, constant: -20),
            customDurationContentView.heightAnchor.constraint(equalToConstant: 300),
            customDurationBottomConstraint
        ])
        
        customDurationContentView.addSubview(customDurationCloseButton)
        customDurationCloseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customDurationCloseButton.topAnchor.constraint(equalTo: customDurationContentView.topAnchor, constant: 8),
            customDurationCloseButton.trailingAnchor.constraint(equalTo: customDurationContentView.trailingAnchor, constant: -8),
            customDurationCloseButton.widthAnchor.constraint(equalToConstant: 30),
            customDurationCloseButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        customDurationContentView.addSubview(customDurationPicker)
        customDurationPicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customDurationPicker.bottomAnchor.constraint(equalTo: customDurationContentView.bottomAnchor, constant: -20),
            customDurationPicker.centerXAnchor.constraint(equalTo: customDurationContentView.centerXAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func durationChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 3 {
            // Show animated overlay.
            customDurationOverlay.isHidden = false
            view.layoutIfNeeded() // force layout for animation start.
            self.customDurationBottomConstraint.constant = -20  // new position
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            // Hide overlay if it was previously shown.
            hideCustomDurationOverlay()
        }
    }
    
    @objc private func hideCustomDurationOverlay() {
        self.customDurationBottomConstraint.constant = 400
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.customDurationOverlay.isHidden = true
        })
    }
    
    @objc private func createTask() {
        guard let taskTitle = titleTextField.text, !taskTitle.isEmpty else {
            showAlert(message: "Please enter a task title.")
            return
        }
        
        var durationMinutes: Int = 15
        switch durationSegmentedControl.selectedSegmentIndex {
        case 0:
            durationMinutes = 15
        case 1:
            durationMinutes = 30
        case 2:
            durationMinutes = 60
        case 3:
            durationMinutes = Int(customDurationPicker.countDownDuration / 60)
            if durationMinutes <= 0 {
                showAlert(message: "Please select a valid custom duration.")
                return
            }
        default:
            break
        }
        
        // Determine recurrence
        let recurrence: String = {
            switch recurrenceSegmentedControl.selectedSegmentIndex {
            case 1: return "Daily"
            case 2: return "Weekly"
            case 3: return "Monthly"
            default: return "None"
            }
        }()
        
        let pickedTime = timePicker.date
        let calendar = Calendar.current
        let baseDate = initialDate ?? Date()
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: pickedTime)
        var newComponents = DateComponents()
        newComponents.year = dateComponents.year
        newComponents.month = dateComponents.month
        newComponents.day = dateComponents.day
        newComponents.hour = timeComponents.hour
        newComponents.minute = timeComponents.minute
        newComponents.second = timeComponents.second
        guard let dueDate = calendar.date(from: newComponents) else {
            showAlert(message: "Could not generate due date.")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: dueDate)
        
        let iconIndex = iconSegmentedControl.selectedSegmentIndex
        let categories = ["food", "health", "mail", "exam", "shopping", "exercise", "work"]
        let selectedCategory = (iconIndex >= 0 && iconIndex < categories.count) ? categories[iconIndex] : "general"
        
        // When editing, preserve the original task id.
        let taskId = editingTask?.id ?? UUID()
        
        // Create the task with the duration and recurrence.
        let newTask = ExtendedTask(
            id: taskId,
            title: taskTitle,
            description: notesTextField.text ?? "",
            time: timeString,
            priority: "Medium",
            category: selectedCategory,
            dueDate: dueDate,
            duration: durationMinutes,
            isCompleted: editingTask?.isCompleted ?? false,
            reminderDate: nil,
            notificationId: nil,
            recurrence: recurrenceSegmentedControl.selectedSegmentIndex == 0 ? "None" : recurrenceSegmentedControl.titleForSegment(at: recurrenceSegmentedControl.selectedSegmentIndex) ?? "None",
            cancelledOccurrences: editingTask?.cancelledOccurrences ?? []
        )
        
        if editingTask != nil {
            delegate?.didEditTask(newTask)
        } else {
            delegate?.didCreateNewTask(newTask)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"OK", style: .default))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
