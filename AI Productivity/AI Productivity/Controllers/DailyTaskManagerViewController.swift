import UIKit

class DailyTaskManagerViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - UI Components
    
    // TextField above weekScrollView to display month and year.
    private let monthYearTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        tf.isUserInteractionEnabled = false
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // Instead of a single weekHeaderView, we now use a paging scroll view.
    private var weekScrollView: UIScrollView!
    
    // TableView to display the timeline of tasks.
    private let timelineTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TimelineTaskCell.self, forCellReuseIdentifier: "TimelineTaskCell")
        return tableView
    }()
    
    private let addTaskButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        button.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = UIColor.systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Set the button size consistently.
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        // Add shadow.
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        
        return button
    }()
    
    // Base date for our header – the 1st of the current month.
    private var baseDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        return Calendar.current.date(from: components)!
    }()
    
    fileprivate var tasks: [ExtendedTask] = []
    private var filteredTasks: [ExtendedTask] = []
    private var selectedDate: Date = Date() {
        didSet {
            filterTasksForSelectedDate()
        }
    }
    
    private var weekStartDate: Date!  // The first date (6 months before today)
    private var weekTotalDays: Int = 0
    private var numPages: Int = 0
    private var initialWeekPageSet = false  // Add this flag

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

    private let menuStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Daily Agenda"
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        
        loadTasks()
        selectedDate = Date()
        
        setupMonthYearTextField()
        setupWeekHeader()
        setupTimelineTableView()
        setupAddTaskButton()
        
        // Add tap gesture recognizer to detect taps outside TaskDetailView.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Only set the initial page once.
        if !initialWeekPageSet {
            let calendar = Calendar.current
            let today = Date()
            let dayOffset = calendar.dateComponents([.day], from: weekStartDate, to: today).day ?? 0
            let pageIndex = dayOffset / 7
            let offsetX = CGFloat(pageIndex) * weekScrollView.frame.width
            weekScrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
            updateMonthYearText()
            initialWeekPageSet = true
        }
    }
    
    // MARK: - Persistence Methods
    private func saveTasks() {
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "tasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let savedTasks = try? JSONDecoder().decode([ExtendedTask].self, from: data) {
            tasks = savedTasks
        }
    }
    
    private func setupWeekHeader() {
        // Create a paging scroll view.
        weekScrollView = UIScrollView()
        weekScrollView.isPagingEnabled = true
        weekScrollView.showsHorizontalScrollIndicator = false
        weekScrollView.delegate = self
        weekScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weekScrollView)
        
        // Position weekScrollView below the monthYearTextField.
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            weekScrollView.topAnchor.constraint(equalTo: monthYearTextField.bottomAnchor, constant: 8),
            weekScrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            weekScrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            weekScrollView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Add a content view inside the scroll view.
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        weekScrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: weekScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: weekScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: weekScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: weekScrollView.trailingAnchor),
            contentView.heightAnchor.constraint(equalTo: weekScrollView.heightAnchor)
        ])
        
        let calendar = Calendar.current
        let today = Date()
        // Define the extended range: 6 months back and 6 months ahead.
        guard let startDate = calendar.date(byAdding: .month, value: -6, to: today),
              let endDate = calendar.date(byAdding: .month, value: 6, to: today) else { return }
        weekStartDate = startDate
        // Compute the total day count in the interval.
        let dayComponents = calendar.dateComponents([.day], from: startDate, to: endDate)
        weekTotalDays = (dayComponents.day ?? 0) + 1
        // Group days into pages of 7.
        numPages = Int(ceil(Double(weekTotalDays) / 7.0))
        
        var previousPage: UIView? = nil
        for page in 0..<numPages {
            let pageView = UIView()
            pageView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(pageView)
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                pageView.widthAnchor.constraint(equalTo: weekScrollView.widthAnchor)
            ])
            if let prev = previousPage {
                pageView.leadingAnchor.constraint(equalTo: prev.trailingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            }
            if page == numPages - 1 {
                pageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            }
            previousPage = pageView
            
            // Create a horizontal stack view for 7 day buttons.
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 8
            stack.translatesAutoresizingMaskIntoConstraints = false
            pageView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: pageView.topAnchor),
                stack.bottomAnchor.constraint(equalTo: pageView.bottomAnchor),
                stack.leadingAnchor.constraint(equalTo: pageView.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: pageView.trailingAnchor)
            ])
            
            // For the current page, compute 7 day buttons.
            for dayOffset in 0..<7 {
                let overallOffset = page * 7 + dayOffset
                // If we've passed the total number of days, add a spacer.
                if (overallOffset >= weekTotalDays) {
                    let spacer = UIView()
                    stack.addArrangedSubview(spacer)
                    continue
                }
                guard let date = calendar.date(byAdding: .day, value: overallOffset, to: weekStartDate) else { continue }
                let button = UIButton(type: .system)
                button.titleLabel?.numberOfLines = 2
                button.titleLabel?.textAlignment = .center
                
                // Format the title as "Weekday\nDay"
                let weekdayIndex = calendar.component(.weekday, from: date) - 1
                let weekdaySymbol = calendar.shortWeekdaySymbols[weekdayIndex]
                let dayNumber = calendar.component(.day, from: date)
                let titleString = "\(weekdaySymbol)\n\(dayNumber)"
                button.setTitle(titleString, for: .normal)
                
                // Store the date in the tag by using the integer value of timeIntervalSince1970.
                button.tag = Int(date.timeIntervalSince1970)
                button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
                
                // If this date equals selectedDate, apply selected style.
                if calendar.isDate(date, inSameDayAs: selectedDate) {
                    button.layer.borderWidth = 2
                    button.layer.borderColor = UIColor.systemBlue.cgColor
                    button.layer.cornerRadius = 8
                } else {
                    button.layer.borderWidth = 0
                    button.backgroundColor = .clear
                }
                // Always display today’s text in reddish orange.
                if calendar.isDate(date, inSameDayAs: Date()) {
                    button.setTitleColor(UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), for: .normal)
                } else {
                    // Non-today days are black by default. (Even if selected.)
                    button.setTitleColor(.black, for: .normal)
                }
                stack.addArrangedSubview(button)
            }
        }
    }
    
    private func setupTimelineTableView() {
        view.addSubview(timelineTableView)
        timelineTableView.dataSource = self
        timelineTableView.delegate = self
        
        NSLayoutConstraint.activate([
            timelineTableView.topAnchor.constraint(equalTo: weekScrollView.bottomAnchor, constant: 16),
            timelineTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timelineTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupAddTaskButton() {
        view.addSubview(addTaskButton)
        NSLayoutConstraint.activate([
            addTaskButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTaskButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addTaskButton.widthAnchor.constraint(equalToConstant: 56),
            addTaskButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        addTaskButton.addTarget(self, action: #selector(addTaskButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    // When a day button is tapped we compute the date using baseDate and the button's tag.
    @objc private func dayButtonTapped(_ sender: UIButton) {
        let calendar = Calendar.current
        let newDate = Date(timeIntervalSince1970: TimeInterval(sender.tag))
        selectedDate = newDate

        // Update all buttons’ appearance.
        for contentView in weekScrollView.subviews {
            for pageView in contentView.subviews {
                if let stack = pageView.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                    for view in stack.arrangedSubviews {
                        if let button = view as? UIButton {
                            let buttonDate = Date(timeIntervalSince1970: TimeInterval(button.tag))
                            if calendar.isDate(buttonDate, inSameDayAs: selectedDate) {
                                button.layer.borderWidth = 2
                                button.layer.borderColor = UIColor.systemBlue.cgColor
                                button.layer.cornerRadius = 8
                            } else {
                                button.layer.borderWidth = 0
                                button.backgroundColor = .clear
                            }
                            // Always render today (March 1) with reddish orange text.
                            if calendar.isDate(buttonDate, inSameDayAs: Date()) {
                                button.setTitleColor(UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0), for: .normal)
                            } else {
                                button.setTitleColor(.black, for: .normal)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc private func addTaskButtonTapped() {
        let newTaskVC = NewTaskViewController()
        // Pass the currently selected date to the new task VC.
        newTaskVC.initialDate = selectedDate
        newTaskVC.modalPresentationStyle = .formSheet
        newTaskVC.delegate = self  // Set delegate
        present(newTaskVC, animated: true, completion: nil)
    }
    
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: view)
        // If there's a TaskDetailView and the tap is outside its frame, hide it.
        for subview in view.subviews {
            if let detailView = subview as? TaskDetailView, !detailView.frame.contains(tapLocation) {
                hideTaskDetailView(detailView)
            }
        }
    }
    
    @objc private func startPomodoro() { /* ... */ }
    @objc private func journalButtonTapped() {
        // Already here, or navigate if needed.
    }
    @objc private func homeButtonTapped() {
        let homeVC = HomeScreenViewController()
        navigationController?.pushViewController(homeVC, animated: true)
    }
    @objc private func notesButtonTapped() {
        let notesVC = NotesViewController()
        navigationController?.pushViewController(notesVC, animated: true)
    }
    @objc private func addCalendarTapped() {
        let calendarVC = CalendarViewController()
        navigationController?.pushViewController(calendarVC, animated: true)
    }

    // Inside DailyTaskManagerViewController.swift in filterTasksForSelectedDate()
    private func filterTasksForSelectedDate() {
        let calendar = Calendar.current
        filteredTasks = tasks.filter { task in
            // Show if task's original dueDate is on the selected day…
            if calendar.isDate(task.dueDate, inSameDayAs: selectedDate) {
                return true
            }
            // …or if it's a recurring task that should appear on the selected day.
            else if task.recurrence != "None" {
                // Exclude if the selected day was cancelled
                if task.cancelledOccurrences.contains(where: { calendar.isDate($0, inSameDayAs: selectedDate) }) {
                    return false
                }
                return isRecurringTask(task, for: selectedDate)
            }
            return false
        }
        timelineTableView.reloadData()
    }

    /// Returns true if the recurring task should show on the given date.
    private func isRecurringTask(_ task: ExtendedTask, for date: Date) -> Bool {
        let calendar = Calendar.current
        // Only consider dates on or after the task's original dueDate.
        guard date >= task.dueDate else { return false }
        
        switch task.recurrence {
        case "Daily":
            return true
        case "Weekly":
            // Checks if the difference in weeks is an integer value.
            let components = calendar.dateComponents([.weekOfYear], from: task.dueDate, to: date)
            return (components.weekOfYear ?? 0) >= 0
        case "Monthly":
            // Checks by month difference.
            let components = calendar.dateComponents([.month], from: task.dueDate, to: date)
            return (components.month ?? 0) >= 0 && calendar.component(.day, from: task.dueDate) == calendar.component(.day, from: date)
        default:
            return false
        }
    }

    private func setupMonthYearTextField() {
        view.addSubview(monthYearTextField)
        
        // Set the text color to the same orange as today's button color.
        monthYearTextField.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)
        
        NSLayoutConstraint.activate([
            monthYearTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            monthYearTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            monthYearTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            monthYearTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    // Helper to update month/year text based on the currently visible week.
    private func updateMonthYearText() {
        let calendar = Calendar.current
        let pageIndex = Int(weekScrollView.contentOffset.x / weekScrollView.frame.width)
        if let pageStartDate = calendar.date(byAdding: .day, value: pageIndex * 7, to: weekStartDate),
           let lastDay = calendar.date(byAdding: .day, value: 6, to: pageStartDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            monthYearTextField.text = formatter.string(from: lastDay)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == weekScrollView {
            updateMonthYearText()
        }
    }
    
    func hideTaskDetailView(_ detailView: TaskDetailView) {
        UIView.animate(withDuration: 0.3, animations: {
            detailView.transform = .identity
        }, completion: { _ in
            detailView.removeFromSuperview()
        })
    }
}

// MARK: - UITableViewDataSource & Delegate
extension DailyTaskManagerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return filteredTasks.count
    }
      
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineTaskCell", for: indexPath) as? TimelineTaskCell else {
            return UITableViewCell()
        }
        
        let task = filteredTasks[indexPath.row]
        let previousTask = indexPath.row > 0 ? filteredTasks[indexPath.row - 1] : nil
        let nextTask = indexPath.row < filteredTasks.count - 1 ? filteredTasks[indexPath.row + 1] : nil
        
        cell.configure(with: task, previousTask: previousTask, nextTask: nextTask)
        
        // Toggle task completion when the done button is pressed.
        cell.doneButtonAction = { [weak self] in
            guard let self = self,
                  let idx = self.tasks.firstIndex(where: { $0.id == task.id }) else { return }
            self.tasks[idx].isCompleted.toggle()
            self.saveTasks()
            self.filterTasksForSelectedDate()
        }
        return cell
    }
      
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return 80
    }
    
    // When tapping on the cell, animate upward a detail view showing task details.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = filteredTasks[indexPath.row]
        
        let detailView = TaskDetailView()
        
        // Configure additional info.
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        detailView.dayLabel.text = "Day: \(dateFormatter.string(from: task.dueDate))"
        
        // Configure time: show start (from task.dueDate) and end (computed by adding task.duration minutes)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let startTimeStr = timeFormatter.string(from: task.dueDate)
        let endDate = Calendar.current.date(byAdding: .minute, value: task.duration, to: task.dueDate) ?? task.dueDate
        let endTimeStr = timeFormatter.string(from: endDate)
        detailView.timeLabel.text = "Time: \(startTimeStr) - \(endTimeStr)"
        
        // Display the length (duration) from the durationSegmentedControl value.
        detailView.lengthLabel.text = "Length: \(task.duration) min"
        
        // Configure notes.
        detailView.notesLabel.text = "Notes: \(task.description)"
        
        // Configure actions.
        detailView.deleteAction = { [weak self, weak detailView] in
            guard let self = self else { return }
            // If task is recurring, ask user which deletion option to perform.
            if task.recurrence != "None" {
                let alert = UIAlertController(title: "Delete Recurring Task", message: "Do you want to delete only this occurrence or all tasks in the series?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Only This", style: .destructive, handler: { _ in
                    self.deleteTaskOccurrence(task)
                    if let dv = detailView { self.hideTaskDetailView(dv) }
                }))
                alert.addAction(UIAlertAction(title: "Delete All", style: .destructive, handler: { _ in
                    self.deleteAllRecurringTasks(task)
                    if let dv = detailView { self.hideTaskDetailView(dv) }
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                // Delete non-recurring task normally.
                if let idx = self.tasks.firstIndex(where: { $0.id == task.id }) {
                    self.tasks.remove(at: idx)
                    self.saveTasks()
                    self.filterTasksForSelectedDate()
                }
                if let dv = detailView {
                    self.hideTaskDetailView(dv)
                }
            }
        }
        
        detailView.editAction = { [weak self, weak detailView] in
            self?.presentEditTaskView(for: task)
            if let dv = detailView {
                self?.hideTaskDetailView(dv)
            }
        }

        detailView.closeAction = { [weak self, weak detailView] in
            // Remove the detail view from its superview (or animate it out)
            UIView.animate(withDuration: 0.3, animations: {
                detailView?.alpha = 0
            }, completion: { _ in
                detailView?.removeFromSuperview()
                // Optionally, restore tab bar visibility:
                self?.tabBarController?.tabBar.isHidden = false
            })
        }
        
        // Present detail view (animation code as in your existing implementation)
        detailView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailView)
        
        let detailHeight: CGFloat = 200
        NSLayoutConstraint.activate([
           detailView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
           detailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
           detailView.heightAnchor.constraint(equalToConstant: detailHeight),
           detailView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: detailHeight)
        ])
        view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.3) {
           detailView.transform = CGAffineTransform(translationX: 0, y: -detailHeight - 40)
        }
    }

}

extension DailyTaskManagerViewController: NewTaskViewControllerDelegate {
    func didCreateNewTask(_ task: ExtendedTask) {
        tasks.append(task)
        tasks.sort { $0.dueDate < $1.dueDate }
        saveTasks()
        filterTasksForSelectedDate()
    }
    
    func didEditTask(_ task: ExtendedTask) {
        // Use the unique identifier to update the task.
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        saveTasks()
        filterTasksForSelectedDate()
    }
}

extension DailyTaskManagerViewController {
    func presentEditTaskView(for task: ExtendedTask) {
        let editTaskVC = NewTaskViewController()
        editTaskVC.initialDate = task.dueDate
        editTaskVC.editingTask = task
        editTaskVC.delegate = self
        present(editTaskVC, animated: true, completion: nil)
    }
}

// In DailyTaskManagerViewController.swift – inside the extension for deletion helpers
extension DailyTaskManagerViewController {
    private func deleteTaskOccurrence(_ task: ExtendedTask) {
        let calendar = Calendar.current
        // Find the recurring task (its master instance in tasks)
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            // Mark this occurrence as cancelled
            updatedTask.cancelledOccurrences.append(selectedDate)
            tasks[index] = updatedTask
            saveTasks()
            filterTasksForSelectedDate()
        }
    }
    
    private func deleteAllRecurringTasks(_ task: ExtendedTask) {
        // Remove all tasks in the series using the unique identifier.
        tasks.removeAll(where: { $0.id == task.id })
        saveTasks()
        filterTasksForSelectedDate()
    }
}
