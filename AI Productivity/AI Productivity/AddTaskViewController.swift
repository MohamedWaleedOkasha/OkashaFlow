import UIKit
import UserNotifications

class AddTaskViewController: UIViewController, UITextViewDelegate {

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let taskTextField = UITextField()
    private let descriptionTextView = UITextView()
    private let categorySegmentedControl = UISegmentedControl(items: ["Work", "Study", "Personal"])
    private let prioritySegmentedControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private let timeDatePicker = UIDatePicker()
    private let saveButton = UIButton(type: .system)
    
    private let reminderSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let reminderLabel: UILabel = {
        let label = UILabel()
        label.text = "Set Reminder"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let reminderDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.isHidden = true
        return picker
    }()
    
    private let dueDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Select Due Date"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let subtaskToggle: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()
    
    private let subtaskToggleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Subtasks"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtasksStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()
    
    private let addSubtaskButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        button.setImage(UIImage(systemName: "plus.circle", withConfiguration: config), for: .normal)
        button.tintColor = .systemGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Add this property for the placeholder.
    private let descriptionPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter note"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        title = "Add Task"
        
        // Set background based on user interface style.
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        
        setupScrollView()
        setupUI()
        requestNotificationPermission()
        
        // Set the description text view delegate.
        descriptionTextView.delegate = self

        reminderSwitch.addTarget(self, action: #selector(reminderSwitchChanged), for: .valueChanged)
        subtaskToggle.addTarget(self, action: #selector(subtaskToggleChanged), for: .valueChanged)
        addSubtaskButton.addTarget(self, action: #selector(addSubtaskRow), for: .touchUpInside)
        
        // Add tap gesture recognizer on the scroll view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        scrollView.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Setup ScrollView & Content View
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            // ScrollView fills the entire view.
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Content view constrained to scrollView.
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            // Maintain same width for vertical scrolling.
            contentView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Configure text fields and views.
        taskTextField.placeholder = "Enter task title"
        taskTextField.borderStyle = .roundedRect
        taskTextField.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.font = .systemFont(ofSize: 16)
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the placeholder label as a subview of descriptionTextView.
        descriptionTextView.addSubview(descriptionPlaceholderLabel)
        NSLayoutConstraint.activate([
            descriptionPlaceholderLabel.topAnchor.constraint(equalTo: descriptionTextView.topAnchor, constant: 8),
            descriptionPlaceholderLabel.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor, constant: 12)
        ])
        
        categorySegmentedControl.selectedSegmentIndex = 0
        categorySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        prioritySegmentedControl.selectedSegmentIndex = 1
        prioritySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        timeDatePicker.datePickerMode = .dateAndTime
        timeDatePicker.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.4, *) {
            timeDatePicker.preferredDatePickerStyle = .wheels
        }
        
        saveButton.setTitle("Save Task", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.layer.cornerRadius = 8
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Add elements to the view
        contentView.addSubview(taskTextField)
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(categorySegmentedControl)
        contentView.addSubview(prioritySegmentedControl)
        contentView.addSubview(dueDateLabel)
        contentView.addSubview(timeDatePicker)
        contentView.addSubview(reminderLabel)
        contentView.addSubview(reminderSwitch)
        contentView.addSubview(reminderDatePicker)
        contentView.addSubview(saveButton)
        contentView.addSubview(subtaskToggleLabel)
        contentView.addSubview(subtaskToggle)
        contentView.addSubview(subtasksStackView)
        contentView.addSubview(addSubtaskButton)
        
        // Initially hide the add subtask button if the toggle is off.
        addSubtaskButton.isHidden = true
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            taskTextField.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            taskTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            taskTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            descriptionTextView.topAnchor.constraint(equalTo: taskTextField.bottomAnchor, constant: 20),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 100),
            
            categorySegmentedControl.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            categorySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categorySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            prioritySegmentedControl.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor, constant: 20),
            prioritySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            prioritySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            subtaskToggleLabel.topAnchor.constraint(equalTo: prioritySegmentedControl.bottomAnchor, constant: 20),
            subtaskToggleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            subtaskToggle.centerYAnchor.constraint(equalTo: subtaskToggleLabel.centerYAnchor),
            subtaskToggle.leadingAnchor.constraint(equalTo: subtaskToggleLabel.trailingAnchor, constant: 10),
            
            subtasksStackView.topAnchor.constraint(equalTo: subtaskToggleLabel.bottomAnchor, constant: 12),
            subtasksStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtasksStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            addSubtaskButton.topAnchor.constraint(equalTo: subtasksStackView.bottomAnchor, constant: 8),
            addSubtaskButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            dueDateLabel.topAnchor.constraint(equalTo: addSubtaskButton.bottomAnchor, constant: 20),
            dueDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dueDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            timeDatePicker.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: 8),
            timeDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timeDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            reminderLabel.topAnchor.constraint(equalTo: timeDatePicker.bottomAnchor, constant: 20),
            reminderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            reminderSwitch.centerYAnchor.constraint(equalTo: reminderLabel.centerYAnchor),
            reminderSwitch.leadingAnchor.constraint(equalTo: reminderLabel.trailingAnchor, constant: 10),
            
            reminderDatePicker.topAnchor.constraint(equalTo: reminderLabel.bottomAnchor, constant: 10),
            reminderDatePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            reminderDatePicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: reminderDatePicker.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            // Bottom constraint to ensure contentView's height is defined for scrolling.
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - UITextViewDelegate Methods
    func textViewDidChange(_ textView: UITextView) {
        // Hide placeholder if there is text; show if empty.
        descriptionPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
    
    // MARK: - Actions
    @objc private func reminderSwitchChanged() {
        reminderDatePicker.isHidden = !reminderSwitch.isOn
        if reminderSwitch.isOn {
            reminderDatePicker.setDate(timeDatePicker.date, animated: true)
        }
    }
    
    @objc private func subtaskToggleChanged() {
        subtasksStackView.isHidden = !subtaskToggle.isOn
        addSubtaskButton.isHidden = !subtaskToggle.isOn
        if subtaskToggle.isOn && subtasksStackView.arrangedSubviews.isEmpty {
            addSubtaskRow()
        }
    }
    
    @objc private func addSubtaskRow() {
        let row = createSubtaskRow()
        subtasksStackView.addArrangedSubview(row)
    }
    
    private func createSubtaskRow() -> UIStackView {
        let textField = UITextField()
        textField.placeholder = "Enter subtask"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        let deleteButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        deleteButton.setImage(UIImage(systemName: "minus.circle", withConfiguration: config), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteSubtaskRow(_:)), for: .touchUpInside)
        
        let rowStack = UIStackView(arrangedSubviews: [textField, deleteButton])
        rowStack.axis = .horizontal
        rowStack.spacing = 8
        return rowStack
    }
    
    @objc private func deleteSubtaskRow(_ sender: UIButton) {
        if let row = sender.superview as? UIStackView {
            subtasksStackView.removeArrangedSubview(row)
            row.removeFromSuperview()
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Save Task
    @objc private func saveButtonTapped() {
        taskTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
        
        guard let taskTitle = taskTextField.text, !taskTitle.isEmpty else {
            showAlert(message: "Task title cannot be empty.")
            return
        }
        
        let description = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let selectedCategoryIndex = categorySegmentedControl.selectedSegmentIndex
        let category = categorySegmentedControl.titleForSegment(at: selectedCategoryIndex) ?? "Work"
        let selectedPriorityIndex = prioritySegmentedControl.selectedSegmentIndex
        let priority = prioritySegmentedControl.titleForSegment(at: selectedPriorityIndex) ?? "Medium"
        let dueDate = timeDatePicker.date
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let formattedTime = formatter.string(from: dueDate)
        
        let notificationId = UUID().uuidString
        
        var subtasks: [String] = []
        if subtaskToggle.isOn {
            subtasks = subtasksStackView.arrangedSubviews.compactMap { view in
                if let stack = view as? UIStackView,
                   let textField = stack.arrangedSubviews.first as? UITextField,
                   let text = textField.text,
                   !text.isEmpty {
                    return text
                }
                return nil
            }
        }
        
        if reminderSwitch.isOn {
            let reminderDate = reminderDatePicker.date
            guard reminderDate > Date() else {
                showAlert(message: "Reminder time must be in the future.")
                return
            }
        }
        
        let newTask = Task(
            title: taskTitle,
            description: description,
            time: formattedTime,
            priority: priority,
            category: category,
            dueDate: dueDate,
            isCompleted: false,
            reminderDate: reminderSwitch.isOn ? reminderDatePicker.date : nil,
            notificationId: reminderSwitch.isOn ? notificationId : nil,
            subtasks: subtasks
        )
        
        NotificationCenter.default.post(name: .taskAdded, object: newTask)
        
        let alert = UIAlertController(title: "Saved!", message: "Your task has been saved successfully", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(message: "Failed to request notification permissions: \(error.localizedDescription)")
                    return
                }
                
                if !granted {
                    self?.showAlert(message: "Please enable notifications in Settings to receive task reminders.")
                }
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    private func scheduleNotification(task: Task) {
        guard let reminderDate = task.reminderDate,
              let notificationId = task.notificationId else { return }
        
        guard reminderDate > Date() else {
            showAlert(message: "Reminder time must be in the future")
            return
        }
        print("Reminder date for task \(task.title): \(reminderDate)")
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    self?.showAlert(message: "Please enable notifications in Settings to receive reminders")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Task Reminder"
                content.body = "\(task.title) (\(task.category)) is due \(task.time)!"
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "notification.wav"))
                content.badge = 1
                content.userInfo = ["taskId": notificationId]
                
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
                print("Adding notification request: \(request)")
                
                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showAlert(message: "Failed to schedule notification: \(error.localizedDescription)")
                        } else {
                            let alert = UIAlertController(title: "Reminder Set",
                                                          message: "You will be notified at the specified time.",
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}