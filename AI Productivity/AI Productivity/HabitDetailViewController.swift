import UIKit

class HabitDetailViewController: UIViewController {
    
    var habit: Habit
    var habitIndex: Int?
    // Closure to send updates back.
    var updateHabit: ((Habit) -> Void)?
    
    // UI Elements
    private let totalTimesLabel = UILabel()
    private let currentStreakLabel = UILabel()
    private let highestStreakLabel = UILabel()
    private let scrollView = UIScrollView()
    // We'll no longer use dotStackView directly – instead we will create a grid and keep an array of dots.
    private var dotViews: [UIView] = []
    
    init(habit: Habit, habitIndex: Int?, updateHabit: ((Habit) -> Void)? = nil) {
        self.habit = habit
        self.habitIndex = habitIndex
        self.updateHabit = updateHabit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = habit.title
        setupUI()
        updateUI()
    }
    
    private func setupUI() {
        // Configure labels
        totalTimesLabel.translatesAutoresizingMaskIntoConstraints = false
        currentStreakLabel.translatesAutoresizingMaskIntoConstraints = false
        highestStreakLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimesLabel.font = .systemFont(ofSize: 16)
        currentStreakLabel.font = .systemFont(ofSize: 16)
        highestStreakLabel.font = .systemFont(ofSize: 16)
        
        let labelStack = UIStackView(arrangedSubviews: [totalTimesLabel, currentStreakLabel, highestStreakLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 8
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelStack)
        
        // Configure the scroll view for the dot grid.
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        
        // Create a vertical stack view to hold rows of dots.
        let gridStackView = UIStackView()
        gridStackView.axis = .vertical
        gridStackView.spacing = 8
        gridStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gridStackView)
        
        NSLayoutConstraint.activate([
            labelStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            labelStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scrollView.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            gridStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            gridStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            gridStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            gridStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            gridStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Build the 365-dot grid: 30 dots per row.
        let dotsPerRow = 30
        let totalDots = 365
        let numberOfRows = Int(ceil(Double(totalDots) / Double(dotsPerRow)))
        
        for row in 0..<numberOfRows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 4
            rowStack.alignment = .center
            for col in 0..<dotsPerRow {
                let dayIndex = row * dotsPerRow + col
                if dayIndex >= totalDots { break }
                let dot = UIView()
                dot.translatesAutoresizingMaskIntoConstraints = false
                // Set fixed size for all dots.
                dot.widthAnchor.constraint(equalToConstant: 15).isActive = true
                dot.heightAnchor.constraint(equalToConstant: 15).isActive = true
                dot.layer.cornerRadius = 7.5
                // Initial color based on the habit's completion log.
                let completed = dayIndex < habit.completionLog.count ? habit.completionLog[dayIndex] : false
                dot.backgroundColor = completed ? .green : .lightGray
                
                rowStack.addArrangedSubview(dot)
                dotViews.append(dot)
            }
            gridStackView.addArrangedSubview(rowStack)
        }
    }
    
    private func updateUI() {
        totalTimesLabel.text = "Total Times Done: \(habit.totalTimesDone)"
        currentStreakLabel.text = "Current Streak: \(habit.streak)"
        highestStreakLabel.text = "Highest Streak: \(habit.highestStreak)"
        updateDotColors()
    }
    
    private func updateDotColors() {
        // Update each dot's color based on the completion log.
        for (index, dot) in dotViews.enumerated() {
            let completed = index < habit.completionLog.count ? habit.completionLog[index] : false
            dot.backgroundColor = completed ? .green : .lightGray
        }
    }
}