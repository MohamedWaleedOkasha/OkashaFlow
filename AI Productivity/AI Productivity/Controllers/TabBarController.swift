import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        addTopBorderToTabBar()
    }
    
    private func setupViewControllers() {
        // Instantiate the view controllers
        let homeVC = HomeScreenViewController()
        let dailyTaskManagerVC = DailyTaskManagerViewController()
        let calendarVC = CalendarViewController()
        let notesVC = NotesViewController()
        
        // Wrap each in a navigation controller if needed
        let homeNav = UINavigationController(rootViewController: homeVC)
        let tasksNav = UINavigationController(rootViewController: dailyTaskManagerVC)
        let calendarNav = UINavigationController(rootViewController: calendarVC)
        let notesNav = UINavigationController(rootViewController: notesVC)
        
        // Set tab bar items with titles and SF Symbols
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "list.bullet"), tag: 0)
        tasksNav.tabBarItem = UITabBarItem(title: "Daily Agenda", image: UIImage(systemName: "doc.text.fill"), tag: 1)
        calendarNav.tabBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), tag: 2)
        notesNav.tabBarItem = UITabBarItem(title: "Notes", image: UIImage(systemName: "note.text"), tag: 3)
        
        // Set view controllers of the tab bar
        viewControllers = [homeNav, tasksNav, calendarNav, notesNav]
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