import UIKit

class StudyScheduleViewController: UIViewController {
    
    // MARK: - Properties
    private let subjects: [Subject]
    private var studySessions: [StudySession] = [] {
        didSet {
            saveSessions()
            tableView.reloadData()
        }
    }
    
    // MARK: - UI Components
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(StudySessionCell.self, forCellReuseIdentifier: "StudySessionCell")
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let addTaskButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add Task", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(subjects: [Subject]) {
        self.subjects = subjects
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSessions()
        if studySessions.isEmpty {
            generateInitialSchedule()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Study Schedule"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(addTaskButton)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        addTaskButton.addTarget(self, action: #selector(addTaskTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addTaskButton.topAnchor, constant: -20),
            
            addTaskButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addTaskButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTaskButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            addTaskButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func generateInitialSchedule() {
        let calendar = Calendar.current
        var currentDate = Date()
        
        // Sort subjects by exam date
        let sortedSubjects = subjects.sorted { $0.examDate < $1.examDate }
        
        for subject in sortedSubjects {
            let daysUntilExam = calendar.dateComponents([.day], from: currentDate, to: subject.examDate).day ?? 0
            let chaptersPerDay = max(1, subject.chapters.count / max(1, daysUntilExam))
            
            var remainingChapters = subject.chapters
            var day = 0
            
            while !remainingChapters.isEmpty {
                let chaptersForDay = Array(remainingChapters.prefix(chaptersPerDay))
                remainingChapters.removeFirst(min(chaptersPerDay, remainingChapters.count))
                
                if let sessionDate = calendar.date(byAdding: .day, value: day, to: currentDate) {
                    let session = StudySession(
                        date: sessionDate,
                        chapters: chaptersForDay.map { chapter in 
                            ChapterAssignment(subjectName: subject.name, chapter: chapter)
                        },
                        isBreakDay: day % 5 == 4
                    )
                    studySessions.append(session)
                }
                day += 1
            }
        }
        
        // Sort all sessions by date
        studySessions.sort { $0.date < $1.date }
    }
    
    @objc private func addTaskTapped() {
        let alert = UIAlertController(title: "Add Study Task", message: nil, preferredStyle: .alert)
        
        // Add subject picker
        let subjectPicker = UIPickerView()
        subjectPicker.delegate = self
        subjectPicker.dataSource = self
        alert.view.addSubview(subjectPicker)
        
        // Add date picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        alert.view.addSubview(datePicker)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let selectedSubject = self?.subjects[subjectPicker.selectedRow(inComponent: 0)] else { return }
            
            // Create new session or add to existing
            let newChapters = selectedSubject.chapters.filter { !$0.isCompleted }
            if !newChapters.isEmpty {
                let session = StudySession(
                    date: datePicker.date,
                    chapters: [ChapterAssignment(
                        subjectName: selectedSubject.name,
                        chapter: newChapters[0]
                    )],
                    isBreakDay: false
                )
                self?.studySessions.append(session)
                self?.studySessions.sort { $0.date < $1.date }
            }
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(studySessions) {
            UserDefaults.standard.set(encoded, forKey: "studySessions")
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "studySessions"),
           let decoded = try? JSONDecoder().decode([StudySession].self, from: data) {
            studySessions = decoded
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension StudyScheduleViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studySessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudySessionCell", for: indexPath) as! StudySessionCell
        let session = studySessions[indexPath.row]
        cell.configure(with: session)
        cell.checkboxTapped = { [weak self] in
            self?.studySessions[indexPath.row].chapters[0].chapter.isCompleted.toggle()
        }
        return cell
    }
}

// MARK: - UIPickerView DataSource & Delegate
extension StudyScheduleViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return subjects.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return subjects[row].name
    }
}

// MARK: - Study Session Cell
class StudySessionCell: UITableViewCell {
    private let dateLabel = UILabel()
    private let tasksStack = UIStackView()
    private let checkbox = UIButton(type: .system)
    var checkboxTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let mainStack = UIStackView(arrangedSubviews: [dateLabel, tasksStack])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        tasksStack.axis = .vertical
        tasksStack.spacing = 4
        
        checkbox.setImage(UIImage(systemName: "square"), for: .normal)
        checkbox.addTarget(self, action: #selector(checkboxPressed), for: .touchUpInside)
        
        contentView.addSubview(mainStack)
        contentView.addSubview(checkbox)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: checkbox.leadingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            checkbox.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkbox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkbox.widthAnchor.constraint(equalToConstant: 44),
            checkbox.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func configure(with session: StudySession) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateLabel.text = dateFormatter.string(from: session.date)
        
        tasksStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for assignment in session.chapters {
            let taskLabel = UILabel()
            taskLabel.text = "\(assignment.subjectName): \(assignment.chapter.name)"
            taskLabel.textColor = assignment.chapter.isCompleted ? .systemGreen : .label
            tasksStack.addArrangedSubview(taskLabel)
        }
        
        let isCompleted = session.chapters.allSatisfy { $0.chapter.isCompleted }
        checkbox.setImage(UIImage(systemName: isCompleted ? "checkmark.square.fill" : "square"), for: .normal)
        checkbox.tintColor = isCompleted ? .systemGreen : .systemBlue
    }
    
    @objc private func checkboxPressed() {
        checkboxTapped?()
    }
} 