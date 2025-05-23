import UIKit
import FirebaseAuth
import FirebaseStorage
import UserNotifications

// Notification name for when a task is added.
extension Notification.Name {
    static let taskAdded = Notification.Name("taskAdded")
    static let backgroundColorChanged = Notification.Name("backgroundColorChanged")
}

// Add this property to store the color key
private let backgroundColorKey = "selectedBackgroundColor"

class HomeScreenViewController: UIViewController {
    
    // MARK: - Properties
    private var sideMenuWidth: CGFloat = 250
    private var isSideMenuOpen = false
    private var userProfile: UserProfile?
    
    // MARK: - Persistence Key
    private let tasksKey = "tasksKey"
    
    // MARK: - Data Model
    private var tasks: [Task] = [] {
        didSet {
            saveTasks()
        }
    }
    
    // MARK: - UI Components
    
    // 1. To-Do List TableView
    private let toDoTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(TodoTableViewCell.self, forCellReuseIdentifier: "TodoCell")
        tableView.layer.cornerRadius = 12
        tableView.layer.shadowColor = UIColor.black.cgColor
        tableView.layer.shadowOpacity = 0.1
        tableView.layer.shadowOffset = CGSize(width: 0, height: 2)
        tableView.layer.shadowRadius = 4
        return tableView
    }()
    
    // Floating Add Task Button
    private let addTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Task", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Bottom Navigation Bar
    private let bottomNavBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pomodoroButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "timer", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let aiChatButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        button.setImage(UIImage(systemName: "message.fill", withConfiguration: config), for: .normal)
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
    
    private let userProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .scaleAspectFill
        button.clipsToBounds = true
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return button
    }()
    
    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
    
    private let mainContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // First, add these properties at the top of HomeScreenViewController
    private let colorSelectorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.text = "Background:"
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let colorStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Dashboard"
        
        setupUI()
        
        // Add navigation bar buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: menuButton)
        
        toDoTableView.dataSource = self
        toDoTableView.delegate = self
        
        view.addSubview(mainContentView)
        view.addSubview(addTaskButton)
        view.addSubview(bottomNavBar)
        
        bottomNavBar.addSubview(pomodoroButton)
        bottomNavBar.addSubview(aiChatButton)
        bottomNavBar.addSubview(calendarButton)
        
        // Button targets
        addTaskButton.addTarget(self, action: #selector(addTodoTapped), for: .touchUpInside)
        pomodoroButton.addTarget(self, action: #selector(startPomodoro), for: .touchUpInside)
        aiChatButton.addTarget(self, action: #selector(aiChatTapped), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(addCalendarTapped), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        
        setupLayout()
        loadTasks()
        
        // Listen for new task notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleTaskAdded(_:)), name: .taskAdded, object: nil)
        
        setupTableView()
        
        // Load saved background color
        loadSavedBackgroundColor()
        
        // Listen for background color changes
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(handleBackgroundColorChange(_:)), 
                                             name: .backgroundColorChanged, 
                                             object: nil)
        
        requestNotificationPermission()
    }
    
    // MARK: - Layout Setup
    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            toDoTableView.topAnchor.constraint(equalTo: mainContentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            toDoTableView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 16),
            toDoTableView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -16),
            toDoTableView.bottomAnchor.constraint(equalTo: bottomNavBar.topAnchor, constant: -16),
            
            addTaskButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTaskButton.bottomAnchor.constraint(equalTo: bottomNavBar.topAnchor, constant: -20),
            addTaskButton.widthAnchor.constraint(equalToConstant: 120),
            addTaskButton.heightAnchor.constraint(equalToConstant: 50),
            
            bottomNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomNavBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomNavBar.heightAnchor.constraint(equalToConstant: 80),
            
            pomodoroButton.centerYAnchor.constraint(equalTo: bottomNavBar.centerYAnchor, constant: -10),
            pomodoroButton.leadingAnchor.constraint(equalTo: bottomNavBar.leadingAnchor, constant: 60),
            pomodoroButton.widthAnchor.constraint(equalToConstant: 44),
            pomodoroButton.heightAnchor.constraint(equalToConstant: 44),
            
            aiChatButton.centerYAnchor.constraint(equalTo: bottomNavBar.centerYAnchor, constant: -10),
            aiChatButton.centerXAnchor.constraint(equalTo: bottomNavBar.centerXAnchor),
            aiChatButton.widthAnchor.constraint(equalToConstant: 44),
            aiChatButton.heightAnchor.constraint(equalToConstant: 44),
            
            calendarButton.centerYAnchor.constraint(equalTo: bottomNavBar.centerYAnchor, constant: -10),
            calendarButton.trailingAnchor.constraint(equalTo: bottomNavBar.trailingAnchor, constant: -60),
            calendarButton.widthAnchor.constraint(equalToConstant: 44),
            calendarButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Persistence Methods
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let savedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = savedTasks
        }
        toDoTableView.reloadData()
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    // MARK: - Button Actions
    @objc private func addTodoTapped() {
        let addTaskVC = AddTaskViewController()
        if let nav = self.navigationController {
            nav.pushViewController(addTaskVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: addTaskVC)
            present(nav, animated: true, completion: nil)
        }
    }
    
    @objc private func aiChatTapped() {
        let chatbotVC = ChatbotViewController()
          navigationController?.pushViewController(chatbotVC, animated: true)
    }
    
    @objc private func addCalendarTapped() {
        let calendarVC = CalendarViewController()
        if let nav = self.navigationController {
            nav.pushViewController(calendarVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: calendarVC)
            present(nav, animated: true, completion: nil)
        }
    }
    
    
    @objc private func startPomodoro() {
        // Programmatic segue to Pomodoro (Focus Mode)
        let pomodoroVC = PomodoroViewController()
        if let nav = self.navigationController {
            nav.pushViewController(pomodoroVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: pomodoroVC)
            present(nav, animated: true, completion: nil)
        }
    }
    
    @objc private func handleTaskAdded(_ notification: Notification) {
        if let newTask = notification.object as? Task {
            tasks.append(newTask)
            toDoTableView.reloadData()
        }
    }
    
    @objc private func logoutTapped() {
        do {
            try Auth.auth().signOut()
            // Dismiss the navigation controller to return to the welcome screen
            let welcomeVC = WelcomeViewController()
            welcomeVC.modalPresentationStyle = .fullScreen
            present(welcomeVC, animated: true)
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    @objc private func saveButtonTapped() {
        // Save tasks
        saveTasks()
        
        // Show a success message with haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(title: "Saved!", message: "Your tasks have been saved successfully", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupUI() {
        // Add main content container
        view.addSubview(mainContentView)
        
        // Add main content views to container
        mainContentView.addSubview(toDoTableView)
        mainContentView.addSubview(addTaskButton)
        mainContentView.addSubview(bottomNavBar)
        
        // Add overlay and menu views directly to main view
        view.addSubview(overlayView)
        view.addSubview(sideMenuView)
        sideMenuView.addSubview(menuStackView)
        
        // Setup menu items
        setupMenuItems()
        
        // Setup constraints for main content container
        NSLayoutConstraint.activate([
            mainContentView.topAnchor.constraint(equalTo: view.topAnchor),
            mainContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup constraints for overlay
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Setup constraints for side menu
        NSLayoutConstraint.activate([
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: sideMenuWidth)
        ])
        
        // Setup constraints for menu stack
        NSLayoutConstraint.activate([
            menuStackView.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 20),
            menuStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 20),
            menuStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -20)
        ])
        
        // Set initial transform for side menu
        sideMenuView.transform = CGAffineTransform(translationX: -sideMenuWidth, y: 0)
        
        // Add tap gesture to dismiss menu
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        overlayView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTapOutside() {
        if isSideMenuOpen {
            toggleSideMenu()
        }
    }
    
    @objc private func toggleSideMenu() {
        isSideMenuOpen.toggle()
        overlayView.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            self.sideMenuView.transform = self.isSideMenuOpen ? .identity : CGAffineTransform(translationX: -self.sideMenuWidth, y: 0)
            self.overlayView.alpha = self.isSideMenuOpen ? 1 : 0
            self.mainContentView.alpha = self.isSideMenuOpen ? 0 : 1
            // Hide/show navigation buttons
            self.navigationController?.navigationBar.alpha = self.isSideMenuOpen ? 0 : 1
            // Hide/show pomodoro and footer buttons
            self.pomodoroButton.alpha = self.isSideMenuOpen ? 0 : 1
            self.bottomNavBar.alpha = self.isSideMenuOpen ? 0 : 1
            // Hide/show add task button
            self.addTaskButton.alpha = self.isSideMenuOpen ? 0 : 1
        } completion: { _ in
            if !self.isSideMenuOpen {
                self.overlayView.isHidden = true
            }
        }
    }
    
    private func setupMenuItems() {
        let menuItems = [
            ("Edit Profile", "person.circle.fill"),
            ("Interests", "heart.fill"),
            ("Completed Tasks", "checkmark.circle.fill"),
            ("Daily Reading", "book.fill"),
            ("Exam Scheduler", "calendar.badge.clock"),
            ("Logout", "rectangle.portrait.and.arrow.right")
        ]
        
        let customBlue = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        
        menuItems.forEach { title, imageName in
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setImage(UIImage(systemName: imageName), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.contentHorizontalAlignment = .left
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
            button.tintColor = customBlue
            button.setTitleColor(customBlue, for: .normal)
            button.addTarget(self, action: #selector(menuItemTapped(_:)), for: .touchUpInside)
            menuStackView.addArrangedSubview(button)
        }
        
        // Add color selector view
        colorSelectorView.addSubview(colorLabel)
        colorSelectorView.addSubview(colorStackView)
        
        // Create color buttons with new colors
        let color1 = createColorButton(color: UIColor.systemBlue.withAlphaComponent(0.1))  // Light blue
        let color2 = createColorButton(color: UIColor.systemYellow.withAlphaComponent(0.1))  // Light yellow
        let color3 = createColorButton(color: UIColor.systemPink.withAlphaComponent(0.1))  // Light pink
        let color4 = createColorButton(color: .white)  // White
        // Add buttons to stack
        [color1, color2, color3, color4].forEach { colorStackView.addArrangedSubview($0) }
        
        // Add to menu stack
        menuStackView.addArrangedSubview(UIView())  // Spacer
        menuStackView.addArrangedSubview(colorSelectorView)
        
        // Setup constraints for color selector
        NSLayoutConstraint.activate([
            colorLabel.topAnchor.constraint(equalTo: colorSelectorView.topAnchor),
            colorLabel.leadingAnchor.constraint(equalTo: colorSelectorView.leadingAnchor),
            colorLabel.bottomAnchor.constraint(equalTo: colorSelectorView.bottomAnchor),
            
            colorStackView.centerYAnchor.constraint(equalTo: colorLabel.centerYAnchor),
            colorStackView.leadingAnchor.constraint(equalTo: colorLabel.trailingAnchor, constant: 8),
            colorStackView.trailingAnchor.constraint(lessThanOrEqualTo: colorSelectorView.trailingAnchor),
            
            colorSelectorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
            
            if let imageURL = profile.profileImageURL {
                loadProfileImage(from: imageURL)
            } else {
                // Set default profile image if no custom image is set
                DispatchQueue.main.async { [weak self] in
                    self?.userProfileButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
                }
            }
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.userProfileButton.setImage(image, for: .normal)
            }
        }.resume()
    }
    
    @objc private func userProfileTapped() {
        // TODO: Implement user profile view
        print("User profile tapped")
    }
    
    @objc private func menuItemTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        switch title {
        case "Edit Profile":
            let profileVC = EditProfileViewController()
            navigationController?.pushViewController(profileVC, animated: true)
        case "Interests":
            let interestsVC = InterestsViewController()
            navigationController?.pushViewController(interestsVC, animated: true)
        case "Completed Tasks":
            let completedTasksVC = CompletedTasksViewController()
            navigationController?.pushViewController(completedTasksVC, animated: true)
        case "Daily Reading":
            let readingVC = DailyReadingViewController()
            navigationController?.pushViewController(readingVC, animated: true)
        case "Exam Scheduler":
            let schedulerVC = ExamSchedulerViewController()
            navigationController?.pushViewController(schedulerVC, animated: true)
        case "Logout":
            // Close the menu first
            toggleSideMenu()
            
            // Show confirmation alert
            let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
                do {
                    try Auth.auth().signOut()
                    // Clear any user-specific data
                    UserDefaults.standard.removeObject(forKey: "userProfile")
                    UserDefaults.standard.synchronize()
                    
                    // Create and set welcome screen as root view controller
                    let welcomeVC = WelcomeViewController()
                    let navigationController = UINavigationController(rootViewController: welcomeVC)
                    
                    // Get the window and set its root view controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = navigationController
                        
                        // Add animation for smooth transition
                        UIView.transition(with: window,
                                        duration: 0.3,
                                        options: .transitionCrossDissolve,
                                        animations: nil,
                                        completion: nil)
                    }
                } catch {
                    // Show error alert if logout fails
                    let errorAlert = UIAlertController(title: "Error", 
                                                     message: "Failed to logout: \(error.localizedDescription)", 
                                                     preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(errorAlert, animated: true)
                }
            })
            
            present(alert, animated: true)
            return
        default:
            break
        }
        
        toggleSideMenu()
    }
    
    private func cancelNotification(for task: Task) {
        if let notificationId = task.notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
    }
    
    func setupTableView() {
        toDoTableView.register(CategorySectionHeader.self, 
                             forHeaderFooterViewReuseIdentifier: CategorySectionHeader.reuseIdentifier)
        toDoTableView.sectionHeaderTopPadding = 0
        toDoTableView.backgroundColor = .clear
        toDoTableView.separatorStyle = .none
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CategorySectionHeader.reuseIdentifier) as! CategorySectionHeader
        
        switch section {
        case 0:
            header.configure(with: "Work", color: .systemBlue)
        case 1:
            header.configure(with: "Study", color: .systemGreen)
        case 2:
            header.configure(with: "Personal", color: .systemOrange)
        default:
            break
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .clear
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TodoTableViewCell else { return }
        
        // Get the number of rows in this section
        let numberOfRows = tableView.numberOfRows(inSection: indexPath.section)
        
        // Reset any existing corner radius
        cell.contentView.layer.cornerRadius = 0
        cell.contentView.layer.maskedCorners = []
        
        if indexPath.row == numberOfRows - 1 {
            // This is the last cell in the section
            cell.contentView.layer.cornerRadius = 12
            cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
        
        // Get section color
        let color: UIColor
        switch indexPath.section {
        case 0: color = .systemBlue
        case 1: color = .systemGreen
        case 2: color = .systemOrange
        default: color = .systemGray
        }
        
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 16 // Reduced from 20 for better proportion
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView() // Empty view for spacing
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    // Add this method to create color buttons
    private func createColorButton(color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
        
        // Set fixed size constraints
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 16),
            button.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return button
    }
    
    // Update the colorButtonTapped method
    @objc private func colorButtonTapped(_ sender: UIButton) {
        var selectedColor: UIColor = .white
        
        if sender.backgroundColor == .white {
            selectedColor = .white
        } else if sender.backgroundColor == UIColor.systemBlue.withAlphaComponent(0.1) {
            selectedColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } else if sender.backgroundColor == UIColor.systemYellow.withAlphaComponent(0.1) {
            selectedColor = UIColor.systemYellow.withAlphaComponent(0.1)
        } else if sender.backgroundColor == UIColor.systemPink.withAlphaComponent(0.1) {
            selectedColor = UIColor.systemPink.withAlphaComponent(0.1)
        }
        
        // Save color to UserDefaults using new API
        do {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: selectedColor, requiringSecureCoding: true)
            UserDefaults.standard.set(colorData, forKey: backgroundColorKey)
        } catch {
            print("Error archiving color: \(error)")
        }
        
        // Apply color
        applyBackgroundColor(selectedColor)
        
        // Notify other views
        NotificationCenter.default.post(name: .backgroundColorChanged, object: selectedColor)
    }
    
    // Add this method to apply the background color
    private func applyBackgroundColor(_ color: UIColor) {
        view.backgroundColor = color
        mainContentView.backgroundColor = color
    }
    
    // Add these new methods
    private func loadSavedBackgroundColor() {
        if let colorData = UserDefaults.standard.data(forKey: backgroundColorKey) {
            do {
                if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                    applyBackgroundColor(color)
                }
            } catch {
                print("Error unarchiving color: \(error)")
            }
        }
    }
    
    @objc private func handleBackgroundColorChange(_ notification: Notification) {
        if let color = notification.object as? UIColor {
            applyBackgroundColor(color)
        }
    }
    
    private func clearUserData() {
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize() // Ensure changes are saved
        
        // Optionally, clear any other persistent storage here
        // For example, if using Core Data, you would delete all entities
        // clearCoreData()
        
        // Show a confirmation message
        let alert = UIAlertController(title: "Data Cleared", message: "All user data has been cleared. You can start fresh.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
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
            
            // Register for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - Alert Method
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func scheduleNotification(task: Task) {
        guard let reminderDate = task.reminderDate,
              let notificationId = task.notificationId else { return }
        
        // Check if the reminder date is in the future
        guard reminderDate > Date() else {
            showAlert(message: "Reminder time must be in the future")
            return
        }
        
        // Debugging: Check the reminder date
        print("Reminder date for task \(task.title): \(reminderDate)")
        
        // First, check notification authorization status
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    self?.showAlert(message: "Please enable notifications in Settings to receive reminders")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "Task Reminder"
                content.body = "\(task.title) (\(task.category)) is due \(task.time)!"
                content.sound = UNNotificationSound.default
                content.badge = 1
                content.userInfo = ["taskId": notificationId]
                
                // Calculate components for the trigger
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
                
                // Debugging: Check if the request is added
                print("Adding notification request: \(request)")
                
                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showAlert(message: "Failed to schedule notification: \(error.localizedDescription)")
                        } else {
                            // Show success message
                            let alert = UIAlertController(title: "Reminder Set", message: "You will be notified at the specified time.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(alert, animated: true)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension HomeScreenViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // Work, Study, Personal
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let activeTasks = tasks.filter { !$0.isCompleted }
        let category: String
        switch section {
        case 0: category = "Work"
        case 1: category = "Study"
        case 2: category = "Personal"
        default: category = ""
        }
        
        return activeTasks.filter { $0.category == category }.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoTableViewCell
        let activeTasks = tasks.filter { !$0.isCompleted }
        
        let category: String
        switch indexPath.section {
        case 0: category = "Work"
        case 1: category = "Study"
        case 2: category = "Personal"
        default: category = ""
        }
        
        // Get tasks for this category and sort by priority
        let categoryTasks = activeTasks.filter { $0.category == category }
            .sorted { task1, task2 in
                let priorityOrder = ["High": 0, "Medium": 1, "Low": 2]
                return (priorityOrder[task1.priority] ?? 3) < (priorityOrder[task2.priority] ?? 3)
            }
        
        let task = categoryTasks[indexPath.row]
        cell.configure(task: task)
        
        // Add priority indicator
        cell.configurePriority(task.priority)
        
        cell.removeAction = { [weak self] in
            if let index = self?.tasks.firstIndex(where: { $0.title == task.title }) {
                self?.cancelNotification(for: task)
                self?.tasks[index].isCompleted = true
                tableView.reloadData()
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Get the active tasks
            let activeTasks = tasks.filter { !$0.isCompleted }
            
            // Determine the section tasks based on the section
            let sectionTasks: [Task]
            switch indexPath.section {
            case 0:
                sectionTasks = activeTasks.filter { $0.category == "Work" }
            case 1:
                sectionTasks = activeTasks.filter { $0.category == "Study" }
            case 2:
                sectionTasks = activeTasks.filter { $0.category == "Personal" }
            default:
                sectionTasks = []
            }
            
            // Ensure the index is valid before accessing it
            guard indexPath.row < sectionTasks.count else {
                print("Index out of range for sectionTasks")
                return
            }
            
            let taskToDelete = sectionTasks[indexPath.row]
            
            // Cancel notification before deleting
            cancelNotification(for: taskToDelete)
            
            // Remove the task from the main tasks array
            if let index = tasks.firstIndex(where: { $0.title == taskToDelete.title && $0.dueDate == taskToDelete.dueDate }) {
                tasks.remove(at: index)
                tableView.reloadData() // Reload all sections
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let activeTasks = tasks.filter { !$0.isCompleted }
        let sectionTasks: [Task]
        
        switch indexPath.section {
        case 0:
            sectionTasks = activeTasks.filter { $0.category == "Work" }
        case 1:
            sectionTasks = activeTasks.filter { $0.category == "Study" }
        case 2:
            sectionTasks = activeTasks.filter { $0.category == "Personal" }
        default:
            sectionTasks = []
        }
        
        // Ensure the index is valid before accessing it
        guard indexPath.row < sectionTasks.count else {
            print("Index out of range for sectionTasks")
            return
        }
        
        let task = sectionTasks[indexPath.row]
        showTaskDetails(task)
    }
    
    private func showTaskDetails(_ task: Task) {
        let alert = UIAlertController(title: task.title, message: nil, preferredStyle: .alert)
        
        // Create date formatter for the due date
        let dueDateFormatter = DateFormatter()
        dueDateFormatter.dateFormat = "MMM d, h:mm a"
        let formattedDueDate = dueDateFormatter.string(from: task.dueDate)
        
        var description = "Description: \(task.description)\nDue: \(formattedDueDate)\nPriority: \(task.priority)\nCategory: \(task.category)"
        
        if let reminderDate = task.reminderDate {
            let reminderFormatter = DateFormatter()
            reminderFormatter.dateFormat = "MMM d, h:mm a"
            description += "\nReminder set for: \(reminderFormatter.string(from: reminderDate))"
        }
        
        alert.message = description
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Custom TableView Cell with Checkbox
class TodoTableViewCell: UITableViewCell {
    
    // UI components for the cell
    private let checkBoxButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.tintColor = .systemGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let taskLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    
    private let overdueIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let priorityIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 4
        return view
    }()
    
    // Closure to handle checkbox action
    var removeAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCellUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCellUI()
    }
    
    private func setupCellUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Add a container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(containerView)
        
        // Add all existing subviews to containerView
        containerView.addSubview(checkBoxButton)
        containerView.addSubview(taskLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(priorityIndicator)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            checkBoxButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            checkBoxButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkBoxButton.widthAnchor.constraint(equalToConstant: 24),
            checkBoxButton.heightAnchor.constraint(equalToConstant: 24),
            
            taskLabel.leadingAnchor.constraint(equalTo: checkBoxButton.trailingAnchor, constant: 8),
            taskLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            priorityIndicator.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            priorityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priorityIndicator.widthAnchor.constraint(equalToConstant: 6),
            priorityIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
        
        checkBoxButton.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
    }
    
    func configure(task: Task) {
        taskLabel.text = task.title
        
        // Format the date to include both date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        timeLabel.text = dateFormatter.string(from: task.dueDate)
        
        // Check if task is overdue
        let isOverdue = task.dueDate < Date()
        overdueIndicator.isHidden = !isOverdue
        
        if isOverdue {
            taskLabel.textColor = .systemRed
            timeLabel.textColor = .systemRed
            contentView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        } else {
            taskLabel.textColor = .label
            timeLabel.textColor = .systemGray
            
            // Set background color based on category
            switch task.category {
            case "Work":
                contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)
            case "Study":
                contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.05)
            case "Personal":
                contentView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.05)
            default:
            contentView.backgroundColor = .systemBackground
            }
        }
        
        // Start unchecked
        checkBoxButton.setImage(UIImage(systemName: "square"), for: .normal)
    }
    
    func configurePriority(_ priority: String) {
        switch priority {
        case "High":
            priorityIndicator.backgroundColor = .systemRed
        case "Medium":
            priorityIndicator.backgroundColor = .systemOrange
        case "Low":
            priorityIndicator.backgroundColor = .systemGreen
        default:
            priorityIndicator.backgroundColor = .systemGray
        }
    }
    
    @objc private func checkBoxTapped() {
        checkBoxButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.removeAction?()
        }
    }
}

// Add this new class for the custom section header
class CategorySectionHeader: UITableViewHeaderFooterView {
    static let reuseIdentifier = "CategorySectionHeader"
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowOpacity = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -0),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    func configure(with title: String, color: UIColor) {
        titleLabel.text = title
        titleLabel.textColor = color
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Add very light background color
        switch title {
        case "Work":
            containerView.backgroundColor = .systemBlue.withAlphaComponent(0.05)
        case "Study":
            containerView.backgroundColor = .systemGreen.withAlphaComponent(0.05)
        case "Personal":
            containerView.backgroundColor = .systemOrange.withAlphaComponent(0.05)
        default:
            containerView.backgroundColor = .systemBackground
        }
    }
}
