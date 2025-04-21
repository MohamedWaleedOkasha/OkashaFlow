import UIKit
import FirebaseAuth
import FirebaseStorage
import UserNotifications

class MainTabBarController: UITabBarController {
    
    // Menu properties moved from HomeScreenViewController
    private let sideMenuWidth: CGFloat = 250
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
    
    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.horizontal.3"), for: .normal)
        button.tintColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        // Clear background instead of systemBackground.
        button.backgroundColor = .clear
        button.layer.cornerRadius = 22  // 44x44 button
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // A simple vertical stack for menu items; reused from HomeScreenViewController styling.
    private let menuStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupMenuUI()
        addTopBorderToTabBar()
        // Force immediate layout so updateMenuButtonVisibility is applied right away.
        view.layoutIfNeeded()  
        updateMenuButtonVisibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMenuButtonVisibility()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the state is correct after layout adjustments
        updateMenuButtonVisibility()
    }
    
    private func updateMenuButtonVisibility() {
        if let nav = selectedViewController as? UINavigationController,
           nav.viewControllers.count == 1 && !isSideMenuOpen {
            menuButton.isHidden = false
        } else {
            menuButton.isHidden = true
        }
    }
    
    private func setupViewControllers() {
        // Instantiate the view controllers
        let homeVC = HomeScreenViewController()
        let dailyTaskManagerVC = DailyTaskManagerViewController()
        let calendarVC = CalendarViewController()
        let notesVC = NotesViewController()
        
        // Wrap each in a navigation controller and set delegate.
        let homeNav = UINavigationController(rootViewController: homeVC)
        let tasksNav = UINavigationController(rootViewController: dailyTaskManagerVC)
        let calendarNav = UINavigationController(rootViewController: calendarVC)
        let notesNav = UINavigationController(rootViewController: notesVC)
        
        // Set self as the navigation delegate for each navigation controller.
        homeNav.delegate = self
        tasksNav.delegate = self
        calendarNav.delegate = self
        notesNav.delegate = self
        
        // Set tab bar items with titles and SF Symbols
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "list.bullet"), tag: 0)
        tasksNav.tabBarItem = UITabBarItem(title: "Daily Agenda", image: UIImage(systemName: "doc.text.fill"), tag: 1)
        calendarNav.tabBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), tag: 2)
        notesNav.tabBarItem = UITabBarItem(title: "Notes", image: UIImage(systemName: "note.text"), tag: 3)
        
        // Set view controllers of the tab bar
        viewControllers = [homeNav, tasksNav, calendarNav, notesNav]
    }
    
    private func setupMenuUI() {
        // Add overlay, side menu, and menu button to the TabBarController's view.
        view.addSubview(overlayView)
        view.addSubview(sideMenuView)
        view.addSubview(menuButton)
        
        // Setup the menu stack with buttons and separators as used in HomeScreenViewController.
        setupMenuItems()
        sideMenuView.addSubview(menuStackView)
        
        // Layout overlay to fill the screen.
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Layout sideMenuView along the left.
        NSLayoutConstraint.activate([
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: sideMenuWidth)
        ])
        
        // Layout menuStackView inside sideMenuView.
        NSLayoutConstraint.activate([
            menuStackView.topAnchor.constraint(equalTo: sideMenuView.safeAreaLayoutGuide.topAnchor, constant: 20),
            menuStackView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor, constant: 20),
            menuStackView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor, constant: -20)
        ])
        
        // Layout the menu button in the top-left corner.
        NSLayoutConstraint.activate([
            // Lower the constant to move the button higher.
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Add tap gesture to overlay and menu button target.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        overlayView.addGestureRecognizer(tapGesture)
        menuButton.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        
        // Ensure the side menu is hidden (off-screen) at launch.
        sideMenuView.transform = CGAffineTransform(translationX: -sideMenuWidth, y: 0)
    }
    
    @objc private func toggleSideMenu() {
        isSideMenuOpen.toggle()
        overlayView.isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.sideMenuView.transform = self.isSideMenuOpen ? .identity : CGAffineTransform(translationX: -self.sideMenuWidth, y: 0)
            self.overlayView.alpha = self.isSideMenuOpen ? 1 : 0
        }, completion: { _ in
            if !self.isSideMenuOpen {
                self.overlayView.isHidden = true
                // Update visibility after closing side menu.
                self.updateMenuButtonVisibility()
            }
        })
        
        // Hide the menu button when side menu is active.
        if isSideMenuOpen {
            menuButton.isHidden = true
        }
    }
    
    @objc private func handleTapOutside() {
        if isSideMenuOpen {
            toggleSideMenu()
        }
    }
    
    // New helper function to hide the side menu with animation.
    private func hideSideMenu(completion: @escaping () -> Void) {
        if isSideMenuOpen {
            // Immediately hide the menu button
            menuButton.isHidden = true
            
            UIView.animate(withDuration: 0.3, animations: {
                self.sideMenuView.transform = CGAffineTransform(translationX: -self.sideMenuWidth, y: 0)
                self.overlayView.alpha = 0
            }, completion: { _ in
                self.overlayView.isHidden = true
                self.isSideMenuOpen = false
                completion()
            })
        } else {
            completion()
        }
    }

    @objc private func menuItemTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        // Get the navigation controller from the selected tab.
        guard let nav = selectedViewController as? UINavigationController else { return }
        
        // Hide the menu first, then navigate.
        hideSideMenu {
            switch title {
            // case "Edit Profile":
            //     let profileVC = EditProfileViewController()
            //     nav.pushViewController(profileVC, animated: true)
            case "Interests":
                let interestsVC = InterestsViewController()
                nav.pushViewController(interestsVC, animated: true)
            case "Completed Tasks":
                let completedTasksVC = CompletedTasksViewController()
                nav.pushViewController(completedTasksVC, animated: true)
            case "Daily Reading":
                let readingVC = DailyReadingViewController()
                nav.pushViewController(readingVC, animated: true)
            case "Exam Scheduler":
                let schedulerVC = ExamSchedulerViewController()
                nav.pushViewController(schedulerVC, animated: true)
            case "Pomodoro":
                let pomodoroVC = PomodoroViewController()
                nav.pushViewController(pomodoroVC, animated: true)
            case "Logout":
                let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
                    do {
                        try Auth.auth().signOut()
                        UserDefaults.standard.removeObject(forKey: "userProfile")
                        let welcomeVC = WelcomeViewController()
                        welcomeVC.modalPresentationStyle = .fullScreen
                        self?.present(welcomeVC, animated: true)
                    } catch {
                        let errorAlert = UIAlertController(title: "Error", message: "Logout failed: \(error.localizedDescription)", preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                })
                self.present(alert, animated: true)
                return
            default:
                break
            }
        }
    }
    
    private func setupMenuItems() {
        let menuItems = [
            // ("Edit Profile", "person.crop.circle"),
            ("Interests", "star.fill"),
            ("Completed Tasks", "checkmark.seal.fill"),
            ("Daily Reading", "book.closed.fill"),
            ("Exam Scheduler", "calendar"),
            ("Pomodoro", "timer"),
            ("Logout", "power.circle.fill")
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
    
    private func addTopBorderToTabBar() {
        let border = UIView()
        border.translatesAutoresizingMaskIntoConstraints = false
        border.backgroundColor = UIColor.lightGray
        
        tabBar.addSubview(border)
        NSLayoutConstraint.activate([
            border.topAnchor.constraint(equalTo: tabBar.topAnchor),
            border.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}

// MARK: - UINavigationControllerDelegate
extension MainTabBarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // If the viewController is the root and the side menu is not open, show the menu button immediately.
        if let firstVC = navigationController.viewControllers.first,
           viewController === firstVC && !isSideMenuOpen {
            menuButton.isHidden = false
        } else {
            menuButton.isHidden = true
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Optionally, you can validate the state here again.
        updateMenuButtonVisibility()
    }
}