import UIKit
import UserNotifications

enum Recurrence: String, Codable {
    case daily, weekly, monthly, yearly
}

struct CalendarTask: Codable {
    var title: String
    var date: Date
    var recurrence: Recurrence?
}

class CalendarViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Persistence Key
    private let calendarTasksKey = "calendarTasksKey"
    
    // MARK: - UI Components
    
    // Month navigation header with arrow buttons.
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        return label
    }()
    
    private let prevMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("◀︎", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let nextMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("▶︎", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    // Weekday header row (dynamically shows Sun, Mon, ... Sat)
    private let weekdayStackView: UIStackView = {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let labels = days.map { day -> UILabel in
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            return label
        }
        let stackView = UIStackView(arrangedSubviews: labels)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    // Calendar grid using a collection view.
    private var calendarCollectionView: UICollectionView!
    
    // Button to add a new task.
    private let addTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Task", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Table view to list tasks for the selected day.
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        return tv
    }()
    

    
    private let bottomNavStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.distribution = .equalSpacing
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let pomodoroButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "clock.fill", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let journalButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "book.fill", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let homeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        // Changed to list bullet icon for todo list
        button.setImage(UIImage(systemName: "list.bullet", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let notesButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "note.text", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let calendarButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "calendar", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Data Model & Properties
    
    private var tasks: [CalendarTask] = []  // All tasks.
    private var filteredTasks: [CalendarTask] = []  // Tasks for the selected day.
    // daysInMonth now holds optional Dates to represent blank cells.
    private var daysInMonth: [Date?] = []
    
    // The selectedDate is used for filtering tasks and determining which month to show.
    private var selectedDate: Date = Date() {
        didSet {
            updateMonthLabel()
            computeDaysInMonth(for: selectedDate)
            loadTasksForSelectedDate()
            calendarCollectionView.reloadData()
        }
    }
    
    private let calendar = Calendar.current
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Calendar"

        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor.black
        } else {
            view.backgroundColor = UIColor.systemBackground
        }
        
        setupCalendarCollectionView()
        
        if traitCollection.userInterfaceStyle == .dark {
            // Set the calendar collection view’s background to black in dark mode.
            calendarCollectionView.backgroundColor = UIColor.black
        } else {
            calendarCollectionView.backgroundColor = UIColor.systemBackground
        }
        
        setupUI()
        configureTableView()
        computeDaysInMonth(for: selectedDate)
        updateMonthLabel()
        loadPersistedTasks()
        loadTasksForSelectedDate()
        
        addTaskButton.addTarget(self, action: #selector(addTaskTapped), for: .touchUpInside)
        prevMonthButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)
        nextMonthButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)

        
        // Setup menu
        setupMenuItems()
        
        // Add overlay and side menu to the view
        view.addSubview(overlayView)
        view.addSubview(sideMenuView)
        
        // Set up constraints for overlayView and sideMenuView
        NSLayoutConstraint.activate([
            // Overlay constraints
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Side menu constraints
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: sideMenuWidth)
        ])
        
        // Set initial position of side menu offscreen
        sideMenuView.transform = CGAffineTransform(translationX: -sideMenuWidth, y: 0)
        
        // Add tap gesture to dismiss the menu
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Optionally, add a menu button target to toggle the menu
        // For example:
        // menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleCalendarTaskAdded(_:)), name: .calendarTaskAdded, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the add notes button when the menu tab is open.
        // Adjust the condition (e.g., comparing selectedIndex or view controller identifier) as needed.
        if let selectedVC = tabBarController?.selectedViewController,
           selectedVC.title == "Menu" {
            addTaskButton.isHidden = true
        } else {
            addTaskButton.isHidden = false
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Add header elements.
        view.addSubview(prevMonthButton)
        view.addSubview(monthLabel)
        view.addSubview(nextMonthButton)
        // Add weekday header.
        view.addSubview(weekdayStackView)
        // Add calendar, add task button, and table view.
        view.addSubview(calendarCollectionView)
        view.addSubview(addTaskButton)
        view.addSubview(tableView)
        
        // Layout header: arrow buttons and month label.
        NSLayoutConstraint.activate([
            prevMonthButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            prevMonthButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            prevMonthButton.widthAnchor.constraint(equalToConstant: 30),
            prevMonthButton.heightAnchor.constraint(equalToConstant: 30),
            
            monthLabel.centerYAnchor.constraint(equalTo: prevMonthButton.centerYAnchor),
            monthLabel.leadingAnchor.constraint(equalTo: prevMonthButton.trailingAnchor, constant: 8),
            
            nextMonthButton.centerYAnchor.constraint(equalTo: prevMonthButton.centerYAnchor),
            nextMonthButton.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 8),
            nextMonthButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 30),
            nextMonthButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Layout weekday row below header.
        NSLayoutConstraint.activate([
            weekdayStackView.topAnchor.constraint(equalTo: prevMonthButton.bottomAnchor, constant: 8),
            weekdayStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            weekdayStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            weekdayStackView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        // Layout calendar collection view below the weekday row.
        NSLayoutConstraint.activate([
            calendarCollectionView.topAnchor.constraint(equalTo: weekdayStackView.bottomAnchor, constant: 8),
            calendarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendarCollectionView.heightAnchor.constraint(equalToConstant: 340)
        ])
        
        // Layout add task button.
        NSLayoutConstraint.activate([
            addTaskButton.topAnchor.constraint(equalTo: calendarCollectionView.bottomAnchor, constant: 8),
            addTaskButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Layout table view.
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: addTaskButton.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupCalendarCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        calendarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        calendarCollectionView.backgroundColor = .white
        calendarCollectionView.layer.cornerRadius = 8
        calendarCollectionView.layer.shadowColor = UIColor.black.cgColor
        calendarCollectionView.layer.shadowOpacity = 0.2
        calendarCollectionView.layer.shadowOffset = CGSize(width: 0, height: 2)
        calendarCollectionView.layer.shadowRadius = 4
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate = self
        calendarCollectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: "CalendarDayCell")
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 8
        tableView.layer.shadowColor = UIColor.black.cgColor
        tableView.layer.shadowOpacity = 0.1
        tableView.layer.shadowOffset = CGSize(width: 0, height: 2)
        tableView.layer.shadowRadius = 4
    }
    
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: selectedDate)
    }
    
    // Computes all dates for the month of the given date,
    // including nil placeholders for padding before the first day.
    private func computeDaysInMonth(for date: Date) {
        daysInMonth.removeAll()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return
        }
        
        // Determine how many blank cells are needed.
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let blankCount = firstWeekday - 1
        
        for _ in 0..<blankCount {
            daysInMonth.append(nil)
        }
        
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                daysInMonth.append(dayDate)
            }
        }
    }
    
    // MARK: - Persistence Methods
    
    private func savePersistedTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: calendarTasksKey)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
    
    private func loadPersistedTasks() {
        if let data = UserDefaults.standard.data(forKey: calendarTasksKey),
           let savedTasks = try? JSONDecoder().decode([CalendarTask].self, from: data) {
            tasks = savedTasks
        }
    }
    
    // MARK: - Task Filtering & Helper Methods
    
    private func loadTasksForSelectedDate() {
        let selectedStart = calendar.startOfDay(for: selectedDate)
        filteredTasks = tasks.filter { task in
            let taskStart = calendar.startOfDay(for: task.date)
            if let recurrence = task.recurrence {
                switch recurrence {
                case .daily:
                    return taskStart <= selectedStart
                case .weekly:
                    let taskWeekday = calendar.component(.weekday, from: taskStart)
                    let selectedWeekday = calendar.component(.weekday, from: selectedStart)
                    return taskStart <= selectedStart && taskWeekday == selectedWeekday
                case .monthly:
                    let taskDay = calendar.component(.day, from: taskStart)
                    let selectedDay = calendar.component(.day, from: selectedStart)
                    return taskStart <= selectedStart && taskDay == selectedDay
                case .yearly:
                    let taskComponents = calendar.dateComponents([.month, .day], from: taskStart)
                    let selectedComponents = calendar.dateComponents([.month, .day], from: selectedStart)
                    return taskStart <= selectedStart && taskComponents.month == selectedComponents.month && taskComponents.day == selectedComponents.day
                }
            } else {
                return taskStart == selectedStart
            }
        }
        tableView.reloadData()
    }
    
    // Determines if a given date has one or more tasks.
    private func hasTask(on date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        return tasks.contains { task in
            let taskStart = calendar.startOfDay(for: task.date)
            if let recurrence = task.recurrence {
                switch recurrence {
                case .daily:
                    return taskStart <= dayStart
                case .weekly:
                    let taskWeekday = calendar.component(.weekday, from: taskStart)
                    let dayWeekday = calendar.component(.weekday, from: dayStart)
                    return taskStart <= dayStart && taskWeekday == dayWeekday
                case .monthly:
                    let taskDay = calendar.component(.day, from: taskStart)
                    let day = calendar.component(.day, from: dayStart)
                    return taskStart <= dayStart && taskDay == day
                case .yearly:
                    let taskComponents = calendar.dateComponents([.month, .day], from: taskStart)
                    let dayComponents = calendar.dateComponents([.month, .day], from: dayStart)
                    return taskStart <= dayStart && taskComponents.month == dayComponents.month && taskComponents.day == dayComponents.day
                }
            } else {
                return taskStart == dayStart
            }
        }
    }
    
    // MARK: - Add Task
    
    @objc private func addTaskTapped() {
        let alert = UIAlertController(title: "New Task", message: "Enter task details", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Task Title"
        }
        alert.addTextField { textField in
            textField.placeholder = "Recurrence? (daily/weekly/monthly/yearly or leave blank)"
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let titleText = alert.textFields?[0].text, !titleText.isEmpty else { return }
            let recurrenceText = alert.textFields?[1].text?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let recurrence: Recurrence?
            switch recurrenceText {
            case "daily":
                recurrence = .daily
            case "weekly":
                recurrence = .weekly
            case "monthly":
                recurrence = .monthly
            case "yearly":
                recurrence = .yearly
            default:
                recurrence = nil
            }
            // Use the currently selected date for the new task.
            let newTask = CalendarTask(title: titleText, date: self.selectedDate, recurrence: recurrence)
            self.tasks.append(newTask)
            self.savePersistedTasks()
            self.loadTasksForSelectedDate()
            self.calendarCollectionView.reloadData()
            // Schedule a notification 24 hours before the task date.
            self.scheduleCalendarNotification(for: newTask)
        }
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Month Navigation
    
    @objc private func prevMonthTapped() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    @objc private func nextMonthTapped() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    // MARK: - UICollectionView DataSource & Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return daysInMonth.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarDayCell", for: indexPath) as? CalendarDayCell else {
            return UICollectionViewCell()
        }
        if let dayDate = daysInMonth[indexPath.item] {
            let dayNumber = calendar.component(.day, from: dayDate)
            cell.dayLabel.text = "\(dayNumber)"
            
            // Check if this is the current day and/or selected day.
            let isToday = calendar.isDateInToday(dayDate)
            let isSelected = calendar.isDate(dayDate, inSameDayAs: selectedDate)
            
            if traitCollection.userInterfaceStyle == .dark {
                if isSelected {
                    cell.backgroundColor = UIColor.systemGray
                } else if isToday {
                    cell.backgroundColor = UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 0.3)
                } else {
                    cell.backgroundColor = .black
                }
            } else {
                if isSelected {
                    cell.backgroundColor = UIColor.systemGray.withAlphaComponent(0.3)
                } else if isToday {
                    cell.backgroundColor = UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 0.3)
                } else {
                    cell.backgroundColor = .white
                }
            }
            
            // Always use the default label color.
            cell.dayLabel.textColor = .label
            
            // Determine the tasks for this day.
            let tasksForDay = tasks(for: dayDate)
            if !tasksForDay.isEmpty {
                // Set indicator: grey if any task is recurring; otherwise blue.
                if tasksForDay.contains(where: { $0.recurrence != nil }) {
                    cell.indicatorView.backgroundColor = UIColor.systemOrange
                } else {
                    cell.indicatorView.backgroundColor = UIColor.blue
                }
                cell.indicatorView.isHidden = false
                
                // Emoji mapping for various task keywords (applies regardless of recurrence).
                let emojiMapping: [String: String] = [
                    "gym": "🏋️‍♂️",
                    "workout": "🏋️‍♂️",
                    "excercise": "🏋️‍♂️",
                    "study": "📚",
                    "read": "📚",
                    "eating": "🍽️",
                    "eat": "🍽️",
                    "food": "🍽️",
                    "dog": "🐶",
                    "pet": "🐶",
                    "walk": "🚶‍♂️",
                    "jog": "🚶‍♂️",
                    "run": "🚶‍♂️",
                    "doctor": "🏥",
                    "hospital": "🏥",
                    "exam":"❗❗",
                    "quiz":"❗❗",
                    "assignment":"❗❗"
                ]
                var foundEmoji: String?
                for (keyword, emoji) in emojiMapping {
                    if tasksForDay.contains(where: { $0.title.lowercased().contains(keyword) }) {
                        foundEmoji = emoji
                        break
                    }
                }
                if let emoji = foundEmoji {
                    cell.emojiLabel.text = emoji
                    cell.emojiLabel.isHidden = false
                } else {
                    cell.emojiLabel.isHidden = true
                }
            } else {
                cell.indicatorView.isHidden = true
                cell.emojiLabel.isHidden = true
            }
        } else {
            cell.dayLabel.text = ""
            cell.backgroundColor = .clear
            cell.indicatorView.isHidden = true
            cell.emojiLabel.isHidden = true
        }
        
        // Existing styling.
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.2
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowRadius = 4
        cell.layer.cornerRadius = 8
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let dayDate = daysInMonth[indexPath.item] {
            selectedDate = dayDate
        }
    }
    
    // Layout: 7 columns.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 12) / 7
        return CGSize(width: width, height: width)
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = filteredTasks[indexPath.row]
        var displayText = task.title
        if let recurrence = task.recurrence {
            displayText += " (\(recurrence.rawValue.capitalized))"
        }
        cell.textLabel?.text = displayText
        return cell
    }
    
    // Enable swipe-to-delete; for recurring tasks, confirm deletion.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let taskToDelete = filteredTasks[indexPath.row]
            if taskToDelete.recurrence != nil {
                let confirmAlert = UIAlertController(title: "Delete Recurring Task", message: "Are you sure you want to delete this recurring task?", preferredStyle: .alert)
                confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    self.deleteTask(taskToDelete)
                }))
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(confirmAlert, animated: true, completion: nil)
            } else {
                deleteTask(taskToDelete)
            }
        }
    }
    
    private func deleteTask(_ task: CalendarTask) {
        if let index = tasks.firstIndex(where: { $0.title == task.title && $0.date == task.date && $0.recurrence == task.recurrence }) {
            tasks.remove(at: index)
            savePersistedTasks()
            loadTasksForSelectedDate()
            calendarCollectionView.reloadData()
        }
    }
    
    // Schedules a notification 24 hours before the calendar task's date.
    private func scheduleCalendarNotification(for day: CalendarTask) {
        // Generate a unique ID for the notification.
        let notificationId = UUID().uuidString
        
        // Create notification content.
        let content = UNMutableNotificationContent()
        content.title = "Calendar Event"
        content.body = "Reminder: \"\(day.title)\" is scheduled for tomorrow."
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        // Calculate the reminder date by subtracting one day from the task date.
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: day.date),
              reminderDate > Date() else {
            print("Reminder date has already passed; notification not scheduled.")
            return
        }
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: "calendar_\(notificationId)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \"\(day.title)\" at \(reminderDate)")
            }
        }
    }
    
    // MARK: - Button Actions
    @objc private func startPomodoro() { /* your code */ }
    @objc private func journalButtonTapped() { /* your code */ }
    @objc private func homeButtonTapped() { /* your code */ }
    @objc private func notesButtonTapped() { /* your code */ }
    @objc private func addCalendarTapped() { /* your code */ }
    
    // MARK: - Menu Related Properties
    
    private var sideMenuWidth: CGFloat = 250
    private var isSideMenuOpen = false
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sideMenuView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let menuStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Menu Setup and Handlers
    
    private func setupMenuItems() {
        // Add the stack view to the side menu view and constrain it
        sideMenuView.addSubview(menuStackView)
        NSLayoutConstraint.activate([
            menuStackView.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 20),
            menuStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 20),
            menuStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -20)
        ])
        
        let menuItems = [
            ("Edit Profile", "person.crop.circle"),
            ("Interests", "sparkles"),
            ("Completed Tasks", "checkmark.seal.fill"),
            ("Daily Reading", "book.circle"),
            ("Daily Agenda", "clock.fill"),
            ("Exam Scheduler", "calendar.circle"),
            ("Logout", "arrow.uturn.backward.circle.fill")
        ]
        
        let customBlue = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        let textColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : customBlue
        
        // Clear any previous menu items if needed
        menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, item) in menuItems.enumerated() {
            let (title, iconName) = item
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setImage(UIImage(systemName: iconName), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 10)
            button.contentHorizontalAlignment = .left
            button.tintColor = textColor
            button.setTitleColor(textColor, for: .normal)
            button.addTarget(self, action: #selector(menuItemTapped(_:)), for: .touchUpInside)
            
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
            ])
            
            menuStackView.addArrangedSubview(container)
            
            if index < menuItems.count - 1 {
                let separator = UIView()
                separator.backgroundColor = .lightGray
                separator.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    separator.heightAnchor.constraint(equalToConstant: 1)
                ])
                menuStackView.addArrangedSubview(separator)
            }
        }
        
        menuStackView.spacing = 10
    }
    
    @objc private func toggleSideMenu() {
        isSideMenuOpen.toggle()
        overlayView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.sideMenuView.transform = self.isSideMenuOpen ? .identity : CGAffineTransform(translationX: -self.sideMenuWidth, y: 0)
            self.overlayView.alpha = self.isSideMenuOpen ? 1 : 0
        } completion: { _ in
            if !self.isSideMenuOpen {
                self.overlayView.isHidden = true
            }
        }
    }
    
    @objc private func handleTapOutside() {
        if isSideMenuOpen {
            toggleSideMenu()
        }
    }
    
    @objc private func menuItemTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        switch title {
        case "Edit Profile":
            // Navigate to Edit Profile
            print("Navigate to Edit Profile")
        case "Interests":
            print("Navigate to Interests")
        case "Completed Tasks":
            print("Navigate to Completed Tasks")
        case "Daily Reading":
            print("Navigate to Daily Reading")
        case "Daily Agenda":
            print("Navigate to Daily Agenda")
        case "Exam Scheduler":
            print("Navigate to Exam Scheduler")
        case "Logout":
            toggleSideMenu()
            let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
                // Add your logout logic here
                print("User Logged Out")
            })
            present(alert, animated: true)
            return
        default:
            break
        }
        
        toggleSideMenu()
    }
}

extension CalendarViewController {
    
    private func tasks(for day: Date) -> [CalendarTask] {
        // Return tasks that apply for the given day.
        return tasks.filter { task in
            let taskStart = calendar.startOfDay(for: task.date)
            let dayStart = calendar.startOfDay(for: day)
            if let recurrence = task.recurrence {
                if task.date <= day {
                    switch recurrence {
                    case .daily:
                        return true
                    case .weekly:
                        let taskWeekday = calendar.component(.weekday, from: taskStart)
                        let dayWeekday = calendar.component(.weekday, from: dayStart)
                        return taskWeekday == dayWeekday
                    case .monthly:
                        let taskDay = calendar.component(.day, from: taskStart)
                        let dayComponent = calendar.component(.day, from: dayStart)
                        return taskDay == dayComponent
                    case .yearly:
                        let taskComponents = calendar.dateComponents([.month, .day], from: taskStart)
                        let dayComponents = calendar.dateComponents([.month, .day], from: dayStart)
                        return (taskComponents.month == dayComponents.month) && (taskComponents.day == dayComponents.day)
                    }
                }
                return false
            } else {
                return taskStart == dayStart
            }
        }
    }
    
    @objc private func handleCalendarTaskAdded(_ notification: Notification) {
        guard let newTask = notification.object as? CalendarTask else { return }
        // Append the new task to your calendar tasks
        tasks.append(newTask)
        // Persist the tasks as needed
        savePersistedTasks()
        // Refresh your UI (e.g., reload a table or collection view)
        tableView.reloadData()
    }
}


