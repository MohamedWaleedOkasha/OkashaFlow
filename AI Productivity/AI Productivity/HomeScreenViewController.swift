import UIKit
import FirebaseAuth
import FirebaseStorage
import UserNotifications

// Notification name for when a task is added.
extension Notification.Name {
    static let taskAdded = Notification.Name("taskAdded")
    static let backgroundColorChanged = Notification.Name("backgroundColorChanged")
}

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
    
    // Floating Add Task Button (updated title)
    // private let addTaskButton: UIButton = {
    //     let button = UIButton(type: .system)
    //     button.setTitle("+", for: .normal)
    //     button.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold) // increased font size and set to bold
    //     button.backgroundColor = UIColor.systemBlue // use system blue color
    //     button.setTitleColor(.white, for: .normal)
    //     button.layer.cornerRadius = 25
    //     button.translatesAutoresizingMaskIntoConstraints = false
        
    //     // Add shadow
    //     button.layer.shadowColor = UIColor.black.cgColor
    //     button.layer.shadowOpacity = 0.3
    //     button.layer.shadowOffset = CGSize(width: 0, height: 2)
    //     button.layer.shadowRadius = 4
        
    //     button.contentHorizontalAlignment = .center
    //     button.contentVerticalAlignment = .center
        
    //     return button
    // }()
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
    // Removed addNotesButton and bottomNavBar properties
    // Removed pomodoroButton and calendarButton as they are now provided via the TabBarController
    
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
    
    // private let menuButton: UIButton = {
    //     let button = UIButton(type: .system)
    //     button.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
    //     button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
    //     // Add a circular background for easier tap area
    //     button.backgroundColor = UIColor.systemBackground
    //     button.layer.cornerRadius = 22  // Assuming a 44x44 button size
    //     button.clipsToBounds = true
    //     button.translatesAutoresizingMaskIntoConstraints = false
    //     return button
    // }()
    
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
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "To-Do List"
        
        setupUI()
                
        // Add navigation bar buttons and set menu button action
        // menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        // navigationItem.leftBarButtonItem = UIBarButtonItem(customView: menuButton)
        
        toDoTableView.dataSource = self
        toDoTableView.delegate = self
        
        // Add the main content (table view) and addTaskButton; removed addNotesButton and bottomNavBar
        view.addSubview(mainContentView)
        view.addSubview(addTaskButton)
        
        // Button target for addTaskButton remains the same
        addTaskButton.addTarget(self, action: #selector(addTodoTapped), for: .touchUpInside)
        
        setupLayout()
        loadTasks()
        
        // Listen for new task notifications
        NotificationCenter.default.addObserver(self, selector: #selector(handleTaskAdded(_:)), name: .taskAdded, object: nil)
        
        setupTableView()
        requestNotificationPermission()
        updateAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Show the tab bar when HomeScreenViewController appears
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Layout Setup
    private func setupLayout() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            // Layout for the table view:
            toDoTableView.topAnchor.constraint(equalTo: mainContentView.safeAreaLayoutGuide.topAnchor, constant: 16),
            toDoTableView.leadingAnchor.constraint(equalTo: mainContentView.leadingAnchor, constant: 16),
            toDoTableView.trailingAnchor.constraint(equalTo: mainContentView.trailingAnchor, constant: -16),
            // Instead of anchoring to bottomNavBar.topAnchor, anchor to safeArea bottom.
            toDoTableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16),
            
            // Layout for the floating addTaskButton:
            addTaskButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTaskButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -20),
            addTaskButton.widthAnchor.constraint(equalToConstant: 56),
            addTaskButton.heightAnchor.constraint(equalToConstant: 56)
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
    
    @objc private func addNotesTapped() {
        let notesVC = NotesViewController()
        navigationController?.pushViewController(notesVC, animated: true)
    }
//
//    @objc private func aiChatTapped() {
//        let chatbotVC = ChatbotViewController()
//          navigationController?.pushViewController(chatbotVC, animated: true)
//    }
    
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
        
        // When adding menuButton to a container (or setting constraints):
//        NSLayoutConstraint.activate([
//            menuButton.widthAnchor.constraint(equalToConstant: 44),
//            menuButton.heightAnchor.constraint(equalToConstant: 44)
//        ])
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
            self.navigationController?.navigationBar.alpha = self.isSideMenuOpen ? 0 : 1
            self.addTaskButton.alpha = self.isSideMenuOpen ? 0 : 1
            // Hide the tab bar when the menu is open.
            self.tabBarController?.tabBar.isHidden = self.isSideMenuOpen
        } completion: { _ in
            if !self.isSideMenuOpen {
                self.overlayView.isHidden = true
            }
        }
    }
    
    // Update setupMenuItems to include Pomodoro:
    private func setupMenuItems() {
        let menuItems = [
            // ("Edit Profile", "person.circle.fill"),
            ("Interests", "heart.fill"),
            ("Completed Tasks", "checkmark.circle.fill"),
            ("Daily Reading", "book.fill"),
            ("Exam Scheduler", "calendar.badge.clock"),
            ("Pomodoro", "timer"),
            ("Logout", "rectangle.portrait.and.arrow.right")
        ]
        
        let customBlue = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        
        // Clear any existing arranged subviews
        menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, item) in menuItems.enumerated() {
            let (title, imageName) = item
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setImage(UIImage(systemName: imageName), for: .normal)
            
            // Increase font size and change weight
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            // Adjust content alignment and spacing between image and title
            button.contentHorizontalAlignment = .left
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
            
            button.tintColor = customBlue
            button.setTitleColor(customBlue, for: .normal)
            button.addTarget(self, action: #selector(menuItemTapped(_:)), for: .touchUpInside)
            menuStackView.addArrangedSubview(button)
            
            // Insert a thin separator between buttons, except after the last one.
            if index < menuItems.count - 1 {
                let separator = UIView()
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
                menuStackView.addArrangedSubview(separator)
                NSLayoutConstraint.activate([
                    separator.heightAnchor.constraint(equalToConstant: 1)
                ])
            }
        }
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
            if let error = error {
                print("Error loading profile image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.userProfileButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
                }
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.userProfileButton.setImage(UIImage(systemName: "person.circle.fill"), for: .normal)
                }
                return
            }
            DispatchQueue.main.async {
                self?.userProfileButton.setImage(image, for: .normal)
            }
        }.resume()
    }
    
    @objc private func userProfileTapped() {
        // TODO: Implement user profile view
        print("User profile tapped")
    }
    
    // Update menuItemTapped switch to handle Pomodoro:
    @objc private func menuItemTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        
        switch title {
        // case "Edit Profile":
        //     let profileVC = EditProfileViewController()
        //     navigationController?.pushViewController(profileVC, animated: true)
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
        case "Pomodoro":    // New case for Pomodoro
            let pomodoroVC = PomodoroViewController()
            navigationController?.pushViewController(pomodoroVC, animated: true)
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
        case 1: color = .systemBlue
        case 2: color = .systemBlue
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
    
//    // Add this method to create color buttons
//    private func createColorButton(color: UIColor) -> UIButton {
//        let button = UIButton(type: .system)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.backgroundColor = color
//        button.layer.cornerRadius = 8
//        button.layer.borderWidth = 1
//        button.layer.borderColor = UIColor.systemGray4.cgColor
//        button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
//
//        // Set fixed size constraints
//        NSLayoutConstraint.activate([
//            button.widthAnchor.constraint(equalToConstant: 16),
//            button.heightAnchor.constraint(equalToConstant: 16)
//        ])
//
//        return button
//    }
//
//    // Update the colorButtonTapped method
//    @objc private func colorButtonTapped(_ sender: UIButton) {
//        var selectedColor: UIColor = .white
//
//        if sender.backgroundColor == .white {
//            selectedColor = .white
//        } else if sender.backgroundColor == UIColor.systemBlue.withAlphaComponent(0.1) {
//            selectedColor = UIColor.systemBlue.withAlphaComponent(0.1)
//        } else if sender.backgroundColor == UIColor.systemYellow.withAlphaComponent(0.1) {
//            selectedColor = UIColor.systemYellow.withAlphaComponent(0.1)
//        } else if sender.backgroundColor == UIColor.systemPink.withAlphaComponent(0.1) {
//            selectedColor = UIColor.systemPink.withAlphaComponent(0.1)
//        }
//
//        // Save color to UserDefaults using new API
//        do {
//            let colorData = try NSKeyedArchiver.archivedData(withRootObject: selectedColor, requiringSecureCoding: true)
//            UserDefaults.standard.set(colorData, forKey: backgroundColorKey)
//        } catch {
//            print("Error archiving color: \(error)")
//        }
//
//        // Apply color
//        applyBackgroundColor(selectedColor)
//
//        // Notify other views
//        NotificationCenter.default.post(name: .backgroundColorChanged, object: selectedColor)
//    }
//
//    // Add this method to apply the background color
//    private func applyBackgroundColor(_ color: UIColor) {
//        let opaqueColor = color.withAlphaComponent(1.0)
//        view.backgroundColor = opaqueColor
//        mainContentView.backgroundColor = opaqueColor
//    }
    
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
    
    private func updateAppearance() {
        if traitCollection.userInterfaceStyle == .dark {
            view.backgroundColor = .black
            mainContentView.backgroundColor = .black
            // Let the table background be clear so that only the cells show their grey background.
            toDoTableView.backgroundColor = .clear
        } else {
            view.backgroundColor = .white
            mainContentView.backgroundColor = .white
            toDoTableView.backgroundColor = .white
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
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
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alpha = 0
        view.addSubview(overlay)
        
        let detailView = HomeTaskDetailView()
        detailView.translatesAutoresizingMaskIntoConstraints = false
        detailView.configure(with: task)
        
        // When the user taps "x", update the model.
        detailView.updateSubtasksState = { updatedState in
            if let index = self.tasks.firstIndex(where: { $0.title == task.title && $0.dueDate == task.dueDate }) {
                self.tasks[index].subtasksChecked = updatedState
                self.saveTasks()
            }
        }
        
        overlay.addSubview(detailView)
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            detailView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            detailView.widthAnchor.constraint(equalToConstant: 350),
            detailView.heightAnchor.constraint(equalToConstant: 250)
        ])
        
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
        }
        
        detailView.closeAction = {
            UIView.animate(withDuration: 0.3, animations: {
                overlay.alpha = 0
            }) { _ in
                overlay.removeFromSuperview()
            }
        }
    }
}

// MARK: - Custom TableView Cell with Checkbox
class TodoTableViewCell: UITableViewCell {
    
    // UI components for the cell
    private let checkBoxButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        // Updated custom green color RGB(9, 35, 39)
        button.tintColor = UIColor(red: 9/255, green: 35/255, blue: 39/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let taskLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
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

        // Create a container view for layout
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        // Add subviews to containerView (include overdueLabel)
        containerView.addSubview(overdueLabel)
        containerView.addSubview(checkBoxButton)
        containerView.addSubview(taskLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(priorityIndicator)

        NSLayoutConstraint.activate([
            // Container constraints
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // overdueLabel constraints - placed at the left edge
            overdueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            overdueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),

            // Checkbox comes to the right of overdueLabel
            checkBoxButton.leadingAnchor.constraint(equalTo: overdueLabel.trailingAnchor, constant: 8),
            checkBoxButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkBoxButton.widthAnchor.constraint(equalToConstant: 24),
            checkBoxButton.heightAnchor.constraint(equalToConstant: 24),

            // Task label between checkbox and priority indicator
            taskLabel.leadingAnchor.constraint(equalTo: checkBoxButton.trailingAnchor, constant: 8),
            taskLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            taskLabel.trailingAnchor.constraint(lessThanOrEqualTo: priorityIndicator.leadingAnchor, constant: -8),

            // Priority indicator between task label and time label
            priorityIndicator.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            priorityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priorityIndicator.widthAnchor.constraint(equalToConstant: 6),
            priorityIndicator.heightAnchor.constraint(equalToConstant: 6),

            // Time label at the right edge
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        checkBoxButton.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
    }
    // Declare overdueLabel for overdue tasks.
    private let overdueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "❗️"  // One red exclamation mark
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemRed
        label.isHidden = true
        return label
    }()
    func configure(task: Task) {
        taskLabel.text = task.title
        
        // Format date for timeLabel
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        timeLabel.text = dateFormatter.string(from: task.dueDate)
        
        let isOverdue = task.dueDate < Date()
        
        // Instead of changing the text color when overdue,
        // show a single red exclamation mark indicator.
        overdueLabel.text = "❗️"
        overdueLabel.isHidden = !isOverdue
        
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode: use custom dark grey background and white text plus white checkbox
            contentView.backgroundColor = UIColor(red: 28/255, green: 28/255, blue: 28/255, alpha: 1)
            taskLabel.textColor = .white
            timeLabel.textColor = .white
            checkBoxButton.tintColor = .white  // Set checkbox tint color to white in dark mode
        } else {
            // Light mode: white background with dark text and custom checkbox tint
            contentView.backgroundColor = .white
            taskLabel.textColor = .black
            timeLabel.textColor = .systemGray
            checkBoxButton.tintColor = UIColor(red: 9/255, green: 35/255, blue: 39/255, alpha: 1)
        }
        // Ensure the checkbox starts unchecked.
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

// Update the CategorySectionHeader class:

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
        
        // In dark mode, force the title label to be white.
        if traitCollection.userInterfaceStyle == .dark {
            titleLabel.textColor = .white
        } else {
            if title == "Work" || title == "Study" || title == "Personal" {
                titleLabel.textColor = UIColor(red: 14/255, green: 28/255, blue: 54/255, alpha: 1)
            } else {
                titleLabel.textColor = color
            }
        }
        
        containerView.layer.borderWidth = 1
        if title == "Work" || title == "Study" || title == "Personal" {
            containerView.layer.borderColor = UIColor(red: 10/255, green: 36/255, blue: 114/255, alpha: 1).cgColor
        } else {
            containerView.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        }
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Set the background color based on the title.
        let customBackground = UIColor(red: 150/255, green: 205/255, blue: 255/255, alpha: 1)
        switch title {
        case "Work", "Study", "Personal":
            containerView.backgroundColor = customBackground.withAlphaComponent(0.3)
        default:
            containerView.backgroundColor = .systemBackground
        }
    }
}
