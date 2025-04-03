import UIKit

class ExamSchedulerViewController: UIViewController {
    
    // MARK: - Properties
    private var startDate: Date?
    private var endDate: Date?
    private var studyDays: [StudyDay] = [] {
        didSet {
            saveStudyDays()
            collectionView.reloadData()
        }
    }
    
    // MARK: - UI Components
    private let dateRangeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select Study Period", for: .normal)
        // Updated custom blue
        button.backgroundColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let addDayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Day", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(StudyDayCell.self, forCellWithReuseIdentifier: "StudyDayCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the tabBar when this view appears.
        tabBarController?.tabBar.isHidden = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        setupUI()
        loadStudyDays()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Study Schedule"
        view.backgroundColor = .systemBackground
        
        view.addSubview(dateRangeButton)
        view.addSubview(addDayButton)
        view.addSubview(collectionView)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        dateRangeButton.addTarget(self, action: #selector(selectDateRangeTapped), for: .touchUpInside)
        addDayButton.addTarget(self, action: #selector(addDayTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            dateRangeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            dateRangeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            dateRangeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6, constant: -24),
            dateRangeButton.heightAnchor.constraint(equalToConstant: 44),
            
            addDayButton.topAnchor.constraint(equalTo: dateRangeButton.topAnchor),
            addDayButton.leadingAnchor.constraint(equalTo: dateRangeButton.trailingAnchor, constant: 16),
            addDayButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addDayButton.heightAnchor.constraint(equalToConstant: 44),
            
            collectionView.topAnchor.constraint(equalTo: dateRangeButton.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func selectDateRangeTapped() {
        let alert = UIAlertController(title: "Select Study Period", message: nil, preferredStyle: .alert)
        
        // Start Date Picker
        let startDatePicker = UIDatePicker()
        startDatePicker.datePickerMode = .date
        startDatePicker.minimumDate = Date()
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // End Date Picker
        let endDatePicker = UIDatePicker()
        endDatePicker.datePickerMode = .date
        endDatePicker.minimumDate = Date()
        endDatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [
            createLabel(text: "Start Date:"),
            startDatePicker,
            createLabel(text: "End Date:"),
            endDatePicker
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        alert.view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            stackView.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -50)
        ])
        
        alert.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] _ in
            self?.startDate = startDatePicker.date
            self?.endDate = endDatePicker.date
            self?.generateStudyDays()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func addDayTapped() {
        // Find the last study day date
        let nextDate: Date
        if let lastDay = studyDays.max(by: { $0.date < $1.date }) {
            // Add one day to the last study day
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: lastDay.date) ?? Date()
        } else {
            // If no study days exist, start from tomorrow
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }
        
        // Create and add the new study day
        let newStudyDay = StudyDay(date: nextDate, tasks: [])
        studyDays.append(newStudyDay)
        // Sort study days by date
        studyDays.sort { $0.date < $1.date }
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        return label
    }
    
    private func generateStudyDays() {
        guard let start = startDate, let end = endDate else { return }
        
        var currentDate = start
        var newStudyDays: [StudyDay] = []
        
        while currentDate <= end {
            newStudyDays.append(StudyDay(date: currentDate, tasks: []))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        studyDays = newStudyDays
    }
    
    private func saveStudyDays() {
        if let encoded = try? JSONEncoder().encode(studyDays) {
            UserDefaults.standard.set(encoded, forKey: "studyDays")
        }
    }
    
    private func loadStudyDays() {
        if let data = UserDefaults.standard.data(forKey: "studyDays"),
           let decoded = try? JSONDecoder().decode([StudyDay].self, from: data) {
            studyDays = decoded
        }
    }
}

// MARK: - Collection View DataSource & Delegate
extension ExamSchedulerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return studyDays.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StudyDayCell", for: indexPath) as! StudyDayCell
        let studyDay = studyDays[indexPath.item]
        cell.configure(with: studyDay)
        
        cell.addTaskTapped = { [weak self] in
            self?.addTask(for: indexPath.item)
        }
        
        cell.onTaskDeleted = { [weak self] taskIndex in
            self?.studyDays[indexPath.item].tasks.remove(at: taskIndex)
            self?.saveStudyDays()
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 10) / 2
        return CGSize(width: width, height: width)
    }
    
    private func addTask(for dayIndex: Int) {
        let alert = UIAlertController(title: "Add Task", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Task Title"
        }
        
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let taskTitle = alert.textFields?.first?.text, !taskTitle.isEmpty else { return }
            
            let newTask = StudyTask(title: taskTitle)
            self?.studyDays[dayIndex].tasks.append(newTask)
            self?.collectionView.reloadItems(at: [IndexPath(item: dayIndex, section: 0)])
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - Collection View Delegate
extension ExamSchedulerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = UIAction(
                title: "Delete Day",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.deleteStudyDay(at: indexPath)
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
    
    private func deleteStudyDay(at indexPath: IndexPath) {
        // First, update the data source
        studyDays.remove(at: indexPath.item)
        
        // Don't call collectionView.deleteItems here since studyDays property observer 
        // will trigger collectionView.reloadData()
        // collectionView.deleteItems(at: [indexPath]) <- Remove this line
    }
}

// MARK: - Study Day Cell
class StudyDayCell: UICollectionViewCell {
    private let dateLabel = UILabel()
    private let tasksTableView = UITableView()
    private let addButton = UIButton(type: .system)
    
    var tasks: [StudyTask] = []
    var addTaskTapped: (() -> Void)?
    var onTaskDeleted: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        clipsToBounds = true
        
        dateLabel.font = .systemFont(ofSize: 16, weight: .bold)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tasksTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        tasksTableView.dataSource = self
        tasksTableView.delegate = self
        tasksTableView.translatesAutoresizingMaskIntoConstraints = false
        
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(dateLabel)
        contentView.addSubview(tasksTableView)
        contentView.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            dateLabel.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            
            addButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            addButton.widthAnchor.constraint(equalToConstant: 24),
            addButton.heightAnchor.constraint(equalToConstant: 24),
            
            tasksTableView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            tasksTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tasksTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tasksTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with studyDay: StudyDay) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        dateLabel.text = dateFormatter.string(from: studyDay.date)
        
        tasks = studyDay.tasks
        tasksTableView.reloadData()
    }
    
    @objc private func addButtonTapped() {
        addTaskTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Add a long press gesture recognizer to show deletion hint
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        contentView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            // Add visual feedback
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        } else if gesture.state == .ended || gesture.state == .cancelled {
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension StudyDayCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = task.title
        cell.contentConfiguration = config
        
        cell.backgroundColor = task.isCompleted ? .systemGreen.withAlphaComponent(0.3) : .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tasks[indexPath.row].isCompleted.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            onTaskDeleted?(indexPath.row)
            tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}