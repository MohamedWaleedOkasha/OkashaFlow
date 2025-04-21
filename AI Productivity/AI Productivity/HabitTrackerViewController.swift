import UIKit
import UserNotifications

// Simple model for a habit.
struct Habit: Codable {
    var title: String
    var isCompleted: Bool
    var streak: Int
    var frequency: String
    var totalTimesDone: Int
    var highestStreak: Int
    // 365-day completion log (true = completed, false = not)
    var completionLog: [Bool]
}

class HabitTrackerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Properties
    private var habits: [Habit] = []
    
    private let habitsKey = "habitsKey"
    
    // Table View to display habits.
    private let habitTableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "HabitCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    // Button to add new habit.
    private let addHabitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Habit", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Label to display progress summary.
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "Progress: N/A"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Habit Tracker"
        setupUI()
        loadHabits()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(habitTableView)
        view.addSubview(addHabitButton)
        view.addSubview(progressLabel)
        
        habitTableView.dataSource = self
        habitTableView.delegate = self
        
        addHabitButton.addTarget(self, action: #selector(addHabitTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            // Progress label at the top
            progressLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            progressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Table view below progress label
            habitTableView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
            habitTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            habitTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            habitTableView.bottomAnchor.constraint(equalTo: addHabitButton.topAnchor, constant: -20),
            
            // Add habit button at the bottom
            addHabitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addHabitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addHabitButton.widthAnchor.constraint(equalToConstant: 140),
            addHabitButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Data Persistence & Loading (Simplified)
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: habitsKey),
           let savedHabits = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = savedHabits
        } else {
            // If no saved habits, load placeholders with default extra fields.
            habits = [
                Habit(title: "Drink Water", isCompleted: false, streak: 0, frequency: "Daily", totalTimesDone: 0, highestStreak: 0, completionLog: Array(repeating: false, count: 365)),
                Habit(title: "Morning Exercise", isCompleted: false, streak: 0, frequency: "Daily", totalTimesDone: 0, highestStreak: 0, completionLog: Array(repeating: false, count: 365))
            ]
        }
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: habitsKey)
        }
    }
    
    // MARK: - Actions
    @objc private func addHabitTapped() {
        let alert = UIAlertController(title: "New Habit", message: "Enter habit title", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Habit Title"
        }
        alert.addTextField { textField in
            textField.placeholder = "Frequency (Daily/Weekly/Custom)"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let title = alert.textFields?[0].text, !title.isEmpty,
                  let frequency = alert.textFields?[1].text, !frequency.isEmpty else { return }
            let newHabit = Habit(title: title,
                                 isCompleted: false,
                                 streak: 0,
                                 frequency: frequency,
                                 totalTimesDone: 0,
                                 highestStreak: 0,
                                 completionLog: Array(repeating: false, count: 365))
            self?.habits.append(newHabit)
            self?.saveHabits()
            // TODO: Setup reminder notifications if needed.
        }))
        present(alert, animated: true)
    }
    
    // Update progress summary (e.g., percentage of habits completed today)
    private func updateProgressSummary() {
        let total = habits.count
        let completed = habits.filter { $0.isCompleted }.count
        progressLabel.text = "Progress: \(completed) / \(total) habits completed"
        // TODO: Expand with weekly/monthly graphs or stats.
    }
    
    // MARK: - UITableView DataSource & Delegate Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return habits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HabitCell", for: indexPath)
        let habit = habits[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = habit.title
        content.secondaryText = "Streak: \(habit.streak) • \(habit.frequency)"
        cell.contentConfiguration = content
        // Show a detail disclosure button for the detailed view.
        cell.accessoryType = .detailDisclosureButton
        return cell
    }
    
    // Toggle habit completion and update streak.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var habit = habits[indexPath.row]
        
        // Get today's index (0-based day-of-year index).
        guard let todayOrdinal = Calendar.current.ordinality(of: .day, in: .year, for: Date()) else { return }
        let todayIndex = todayOrdinal - 1  // Convert to 0-based index (0...364)
        
        // Toggle completion status only if not already marked today.
        if !habit.completionLog[todayIndex] {
            // Mark as completed for today.
            habit.completionLog[todayIndex] = true
            habit.isCompleted = true
            
            // Update counts.
            habit.streak += 1
            habit.totalTimesDone += 1
            if habit.streak > habit.highestStreak {
                habit.highestStreak = habit.streak
            }
        } else {
            // Optionally, you can allow unmarking for the day.
            // Uncomment below if you want to allow toggling off.
            /*
            habit.completionLog[todayIndex] = false
            habit.isCompleted = false
            habit.streak = 0 // or recalc streak if needed
            */
        }
        
        habits[indexPath.row] = habit
        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateProgressSummary()
        saveHabits()
        
        // TODO: Schedule or cancel notifications based on the updated habit state.
    }
    
    // Optional: Enable deletion of habits.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            habits.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateProgressSummary()
            saveHabits()
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let habit = habits[indexPath.row]
        let detailVC = HabitDetailViewController(habit: habit, habitIndex: indexPath.row, updateHabit: { [weak self] updatedHabit in
            guard let self = self else { return }
            self.habits[indexPath.row] = updatedHabit
            self.saveHabits()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            self.updateProgressSummary()
        })
        navigationController?.pushViewController(detailVC, animated: true)
    }
}