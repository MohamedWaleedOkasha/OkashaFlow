import UIKit
import UserNotifications

class AddTaskViewController: UIViewController {
    
    // MARK: - UI Elements
    private let taskTextField = UITextField()
    private let descriptionTextView = UITextView()
    private let categorySegmentedControl = UISegmentedControl(items: ["Work", "Study", "Personal"])
    private let prioritySegmentedControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private let timeDatePicker = UIDatePicker()
    private let saveButton = UIButton(type: .system)
    
    // Add reminder switch and date picker
    private let reminderSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        return switchControl
    }()
    
    private let reminderLabel: UILabel = {
        let label = UILabel()
        label.text = "Set Reminder"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)  // Updated font to match dueDateLabel
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        title = "Add Task"
        
        // Set the background color based on user interface style.
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = .black
        } else {
            view.backgroundColor = .white
        }
        
        // Configure UI elements to respect system appearance
        if #available(iOS 13.0, *) {
            descriptionTextView.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.1)
            taskTextField.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.1)
        } else {
            descriptionTextView.backgroundColor = .white.withAlphaComponent(0.1)
            taskTextField.backgroundColor = .white.withAlphaComponent(0.1)
        }
        
        // Add save button to navigation bar with a prominent style
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveButtonTapped))
        saveButton.tintColor = UIColor.systemBlue
        navigationItem.rightBarButtonItem = saveButton
        
        setupUI()
        requestNotificationPermission()
        
        // Add target for reminder switch
        reminderSwitch.addTarget(self, action: #selector(reminderSwitchChanged), for: .valueChanged)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        // Ensure UI elements have appropriate backgrounds
        descriptionTextView.backgroundColor = .clear
        timeDatePicker.backgroundColor = .clear
        reminderDatePicker.backgroundColor = .clear
        
        // For text input elements, use system-appropriate colors
        if #available(iOS 13.0, *) {
            taskTextField.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.1)
            descriptionTextView.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.1)
        } else {
            taskTextField.backgroundColor = .white.withAlphaComponent(0.1)
            descriptionTextView.backgroundColor = .white.withAlphaComponent(0.1)
        }
        
        // Make sure segmented controls are transparent
        categorySegmentedControl.backgroundColor = .clear
        prioritySegmentedControl.backgroundColor = .clear
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        // Configure Task Text Field
        taskTextField.placeholder = "Enter task title"
        taskTextField.borderStyle = .roundedRect
        taskTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure Description Text View
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor.systemGray4.cgColor
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.font = .systemFont(ofSize: 16)
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure Category Segmented Control
        categorySegmentedControl.selectedSegmentIndex = 0
        categorySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure Priority Segmented Control
        prioritySegmentedControl.selectedSegmentIndex = 1
        prioritySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure Due Date Label and Date Picker
        timeDatePicker.datePickerMode = .dateAndTime
        timeDatePicker.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.4, *) {
            timeDatePicker.preferredDatePickerStyle = .wheels
        }
        
        // Configure Save Button
        saveButton.setTitle("Save Task", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.layer.cornerRadius = 8
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        // Add elements to the view
        view.addSubview(taskTextField)
        view.addSubview(descriptionTextView)
        view.addSubview(categorySegmentedControl)
        view.addSubview(prioritySegmentedControl)
        view.addSubview(dueDateLabel)
        view.addSubview(timeDatePicker)
        view.addSubview(reminderLabel)
        view.addSubview(reminderSwitch)
        view.addSubview(reminderDatePicker)
        view.addSubview(saveButton)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            taskTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            taskTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            taskTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            descriptionTextView.topAnchor.constraint(equalTo: taskTextField.bottomAnchor, constant: 20),
            descriptionTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 100),
            
            categorySegmentedControl.topAnchor.constraint(equalTo: descriptionTextView.bottomAnchor, constant: 20),
            categorySegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            categorySegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            prioritySegmentedControl.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor, constant: 20),
            prioritySegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            prioritySegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            dueDateLabel.topAnchor.constraint(equalTo: prioritySegmentedControl.bottomAnchor, constant: 20),
            dueDateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dueDateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timeDatePicker.topAnchor.constraint(equalTo: dueDateLabel.bottomAnchor, constant: 8),
            timeDatePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeDatePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            reminderLabel.topAnchor.constraint(equalTo: timeDatePicker.bottomAnchor, constant: 20),
            reminderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            reminderSwitch.centerYAnchor.constraint(equalTo: reminderLabel.centerYAnchor),
            reminderSwitch.leadingAnchor.constraint(equalTo: reminderLabel.trailingAnchor, constant: 10),
            
            reminderDatePicker.topAnchor.constraint(equalTo: reminderLabel.bottomAnchor, constant: 10),
            reminderDatePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            reminderDatePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: reminderDatePicker.bottomAnchor, constant: 40),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 150),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func reminderSwitchChanged() {
        reminderDatePicker.isHidden = !reminderSwitch.isOn
        if reminderSwitch.isOn {
            // Set reminder date picker to task due date by default
            reminderDatePicker.setDate(timeDatePicker.date, animated: true)
        }
    }
    
    @objc private func dismissKeyboard() {
        taskTextField.resignFirstResponder()
        descriptionTextView.resignFirstResponder()
    }
    
    // MARK: - Save Task
    @objc private func saveButtonTapped() {
        // Dismiss the keyboard
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
        
        // Format due date as a string
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let formattedTime = formatter.string(from: dueDate)
        
        // Generate notification ID
        let notificationId = UUID().uuidString
        
        // Check if the reminder date is set and in the future
        if reminderSwitch.isOn {
            let reminderDate = reminderDatePicker.date
            guard reminderDate > Date() else {
                showAlert(message: "Reminder time must be in the future.")
                return
            }
            
            // Create a new Task object
            let newTask = Task(
                title: taskTitle,
                description: description,
                time: formattedTime,
                priority: priority,
                category: category,
                dueDate: dueDate,
                isCompleted: false,
                reminderDate: reminderDate,
                notificationId: notificationId
            )
            
            // Schedule notification
            scheduleNotification(task: newTask)
            
            // Debugging: Check if the notification is scheduled
            print("Scheduling notification for task: \(newTask.title) at \(reminderDate)")
            
            // Post notification so Home Screen can update
            NotificationCenter.default.post(name: .taskAdded, object: newTask)
            
            // Show a success message
            let alert = UIAlertController(title: "Saved!", message: "Your task has been saved successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        } else {
            // If reminder is not set, create the task without a reminder
            let newTask = Task(
                title: taskTitle,
                description: description,
                time: formattedTime,
                priority: priority,
                category: category,
                dueDate: dueDate,
                isCompleted: false,
                reminderDate: nil,
                notificationId: nil
            )
            
            // Post notification so Home Screen can update
            NotificationCenter.default.post(name: .taskAdded, object: newTask)
            
            // Show a success message
            let alert = UIAlertController(title: "Saved!", message: "Your task has been saved successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(message: "Failed to request notification permissions: \(error.localizedDescription)")
                    return
                }
                
                if (!granted) {
                    self?.showAlert(message: "Please enable notifications in Settings to receive task reminders.")
                }
            }
            
            // Register for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    private func scheduleNotification(task: Task) {
        guard let reminderDate = task.reminderDate,
              let notificationId = task.notificationId else { return }
        
        // Check if the reminder date is in the future
        guard reminderDate > Date() else {
            showAlert(message: "Reminder time must be in the future")
            return
        }
        
        // Debug: Print the reminder date
        print("Reminder date for task \(task.title): \(reminderDate)")
        
        // Get notification settings and schedule if authorized
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    self?.showAlert(message: "Please enable notifications in Settings to receive reminders")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Task Reminder"
                content.body = "\(task.title) (\(task.category)) is due \(task.time)!"
                // Use the custom sound file
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "notification.wav"))
                content.badge = 1
                content.userInfo = ["taskId": notificationId]
                
                // Calculate trigger components from the reminder date
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
                
                // Debug: Print the request before adding
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
