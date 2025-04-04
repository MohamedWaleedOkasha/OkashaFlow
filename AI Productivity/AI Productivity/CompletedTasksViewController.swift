import UIKit

class CompletedTasksViewController: UIViewController {
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CompletedTaskCell")
        return tableView
    }()
    
    private var completedTasks: [Date: [Task]] = [:]
    private var sortedDates: [Date] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the tabBar when this view appears.
        tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        setupUI()
        loadCompletedTasks()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Completed Tasks"
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadCompletedTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasksKey"),
           let tasks = try? JSONDecoder().decode([Task].self, from: data) {
            let completedTasks = tasks.filter { $0.isCompleted }
            groupTasksByMonth(completedTasks)
        }
    }
    
    private func groupTasksByMonth(_ tasks: [Task]) {
        let calendar = Calendar.current
        completedTasks = Dictionary(grouping: tasks) { task in
            let components = calendar.dateComponents([.year, .month], from: task.dueDate)
            return calendar.date(from: components) ?? task.dueDate
        }
        sortedDates = completedTasks.keys.sorted(by: >)
        tableView.reloadData()
    }
}

extension CompletedTasksViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedDates.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = sortedDates[section]
        return completedTasks[date]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = sortedDates[section]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedTaskCell", for: indexPath)
        let date = sortedDates[indexPath.section]
        if let tasks = completedTasks[date] {
            let task = tasks[indexPath.row]
            var content = cell.defaultContentConfiguration()
            content.text = task.title
            content.secondaryText = task.time
            cell.contentConfiguration = content
            cell.accessoryType = .checkmark
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let date = sortedDates[indexPath.section]
        if let tasks = completedTasks[date] {
            let task = tasks[indexPath.row]
            showTaskDetails(task)
        }
    }
    
    private func showTaskDetails(_ task: Task) {
        let alert = UIAlertController(title: task.title, message: nil, preferredStyle: .alert)
        
        let description = "Description: \(task.description)\nDue: \(task.time)\nPriority: \(task.priority)\nCategory: \(task.category)"
        alert.message = description
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 