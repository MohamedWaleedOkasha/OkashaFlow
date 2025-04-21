import UIKit

struct Note: Codable {
    var title: String
    var content: String
    var creationDate: Date
    var voiceMemoURLs: [String?]  // Optional voice memo file URLs
    var folder: String?           // nil if not assigned to a folder
    var imagePath: String?        // New property to save the note's image
}

struct Folder: Codable {
    var name: String
    var isExpanded: Bool = true
}

class NotesViewController: UIViewController {

    private let notesKey = "notesKey"
    private let foldersKey = "foldersKey"
    
    private var notes: [Note] = [] {
        didSet { saveNotes() }
    }
    
    private var filteredNotes: [Note] = []
    
    // Search controller to filter notes.
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
        return tv
    }()
    
    // List of created folders. Changes trigger saving.
    private var folders: [Folder] = [] {
        didSet { saveFolders() }
    }
    
    // "Add Folder" button shown at the bottom.
    private let addFolderButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(" Add Folder", for: .normal)
        button.setImage(UIImage(systemName: "folder.badge.plus"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return button
    }()
    
    // Helper: Group notes by folder name. Notes with folder == nil are "Uncategorized".
    private func groupedNotes() -> [String: [Note]] {
        var groups: [String: [Note]] = [:]
        for note in notes {
            let key = note.folder ?? "Uncategorized"
            groups[key, default: []].append(note)
        }
        return groups
    }
    
    // Helper: Sorted folder keys. Custom folders appear sorted and "Uncategorized" always at the end.
    private func sortedFolderKeys() -> [String] {
        var keys = Set<String>(groupedNotes().keys)
        for folder in folders {
            keys.insert(folder.name)
        }
        var keyArray = Array(keys.filter { $0 != "Uncategorized" }).sorted()
        if keys.contains("Uncategorized") {
            keyArray.append("Uncategorized")
        }
        return keyArray
    }
    
    // Computed property to return notes that should be displayed.
    private var displayNotes: [Note] {
        if searchController.isActive, let text = searchController.searchBar.text, !text.isEmpty {
            return filteredNotes
        }
        return notes
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        view.backgroundColor = .systemBackground
        
        // Load persisted notes and folders.
        loadNotes()
        loadFolders()
        
        // Setup search controller.
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Notes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Right bar button to add a new note.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addNote))
        tableView.dataSource = self
        tableView.delegate = self
        // Assign both delegates for drag & drop.
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set extra bottom inset for tableView so last note is accessible.
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        
        // Add the "Add Folder" button at the bottom.
        view.addSubview(addFolderButton)
        NSLayoutConstraint.activate([
            addFolderButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            addFolderButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            addFolderButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            addFolderButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        addFolderButton.addTarget(self, action: #selector(addFolderTapped), for: .touchUpInside)
        
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let savedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            notes = savedNotes.sorted(by: { $0.creationDate > $1.creationDate })
        }
    }
    
    private func saveNotes() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: notesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let savedFolders = try? JSONDecoder().decode([Folder].self, from: data) {
            folders = savedFolders
        }
    }
    
    private func saveFolders() {
        if let data = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(data, forKey: foldersKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc private func addNote() {
        let newNote = Note(title: "New Note", content: "", creationDate: Date(), voiceMemoURLs: [])
        notes.insert(newNote, at: 0)
        tableView.reloadData()
        
        let detailVC = NoteDetailViewController(note: newNote, noteIndex: 0)
        detailVC.onSave = { [weak self] updatedNote in
            guard let self = self else { return }
            if let idx = self.notes.firstIndex(where: { $0.creationDate == updatedNote.creationDate }) {
                self.notes[idx] = updatedNote
            }
            self.notes.sort(by: { $0.creationDate > $1.creationDate })
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc private func addFolderTapped() {
        let alert = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Folder Name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            if let folderName = alert.textFields?.first?.text, !folderName.isEmpty {
                self.folders.append(Folder(name: folderName))
                self.tableView.reloadData()
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Bottom Navigation Components

    
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
        // Note: using the list icon
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
    
    // MARK: - Button Actions
    @objc private func startPomodoro() {
        // Implement your pomodoro feature, or navigate to the appropriate controller.
    }
    
    @objc private func journalButtonTapped() {
        let dailyTaskManagerVC = DailyTaskManagerViewController()
        navigationController?.pushViewController(dailyTaskManagerVC, animated: true)
    }
    
    @objc private func homeButtonTapped() {
        let homeVC = HomeScreenViewController()
        navigationController?.pushViewController(homeVC, animated: true)
    }
    
    @objc private func notesButtonTapped() {
        // Already in Notes—optionally refresh or do nothing.
    }
    
    @objc private func addCalendarTapped() {
        let calendarVC = CalendarViewController()
        navigationController?.pushViewController(calendarVC, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate
extension NotesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        // Show one section for search results.
        if searchController.isActive, let text = searchController.searchBar.text, !text.isEmpty {
            return 1
        }
        return sortedFolderKeys().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive, let text = searchController.searchBar.text, !text.isEmpty {
            return displayNotes.count
        }
        
        let key = sortedFolderKeys()[section]
        if key == "Uncategorized" || folders.first(where: { $0.name == key })?.isExpanded ?? true {
            return groupedNotes()[key]?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        
        if searchController.isActive, let text = searchController.searchBar.text, !text.isEmpty {
            let note = displayNotes[indexPath.row]
            cell.textLabel?.text = note.title
        } else {
            let key = sortedFolderKeys()[indexPath.section]
            if let notesInFolder = groupedNotes()[key] {
                let note = notesInFolder[indexPath.row]
                cell.textLabel?.text = note.title
            }
        }
        return cell
    }
    
    // Optionally update header view: hide it when searching.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if searchController.isActive, let text = searchController.searchBar.text, !text.isEmpty {
            return nil
        }
        let key = sortedFolderKeys()[section]
        let header = UITableViewHeaderFooterView(reuseIdentifier: "FolderHeader")
        header.contentView.backgroundColor = .secondarySystemBackground

        // Create a label for the folder title.
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = key
        header.contentView.addSubview(titleLabel)

        var constraints: [NSLayoutConstraint] = [
            titleLabel.centerYAnchor.constraint(equalTo: header.contentView.centerYAnchor)
        ]
        
        if key != "Uncategorized" {
            // Create a toggle button for collapse/expand.
            let toggleButton = UIButton(type: .system)
            toggleButton.translatesAutoresizingMaskIntoConstraints = false
            let isExpanded = folders.first(where: { $0.name == key })?.isExpanded ?? true
            let imageName = isExpanded ? "chevron.down" : "chevron.right"
            toggleButton.setImage(UIImage(systemName: imageName), for: .normal)
            toggleButton.tag = section
            toggleButton.addTarget(self, action: #selector(toggleFolder(_:)), for: .touchUpInside)
            header.contentView.addSubview(toggleButton)
            
            // Create an options button instead of a delete button.
            let optionsButton = UIButton(type: .system)
            optionsButton.translatesAutoresizingMaskIntoConstraints = false
            optionsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
            optionsButton.tintColor = .label
            optionsButton.tag = section
            optionsButton.addTarget(self, action: #selector(folderOptionsTapped(_:)), for: .touchUpInside)
            header.contentView.addSubview(optionsButton)
            
            constraints += [
                toggleButton.leadingAnchor.constraint(equalTo: header.contentView.leadingAnchor, constant: 16),
                toggleButton.centerYAnchor.constraint(equalTo: header.contentView.centerYAnchor),
                
                titleLabel.leadingAnchor.constraint(equalTo: toggleButton.trailingAnchor, constant: 8),
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: optionsButton.leadingAnchor, constant: -8),
                
                optionsButton.trailingAnchor.constraint(equalTo: header.contentView.trailingAnchor, constant: -16),
                optionsButton.centerYAnchor.constraint(equalTo: header.contentView.centerYAnchor)
            ]
        } else {
            // For "Uncategorized", only show the label.
            constraints += [
                titleLabel.leadingAnchor.constraint(equalTo: header.contentView.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: header.contentView.trailingAnchor, constant: -16)
            ]
        }
        
        NSLayoutConstraint.activate(constraints)
        return header
    }

    @objc private func deleteFolderButtonTapped(_ sender: UIButton) {
        // Retrieve the folder name from the header.
        guard let header = sender.superview?.superview as? UITableViewHeaderFooterView,
              let folderName = header.textLabel?.text else { return }
        let alert = UIAlertController(title: "Delete Folder",
                                      message: "Are you sure you want to delete folder \"\(folderName)\"? Notes will become uncategorized.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.folders.removeAll { $0.name == folderName }
            for i in 0..<self.notes.count {
                if self.notes[i].folder == folderName {
                    self.notes[i].folder = nil
                }
            }
            self.tableView.reloadData()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func toggleFolder(_ sender: UIButton) {
        let section = sender.tag
        let key = sortedFolderKeys()[section]
        if let index = folders.firstIndex(where: { $0.name == key }) {
            folders[index].isExpanded.toggle()
            // Update the chevron image.
            let newImage = folders[index].isExpanded ? "chevron.down" : "chevron.right"
            sender.setImage(UIImage(systemName: newImage), for: .normal)
            tableView.reloadData()
        }
    }
    
    @objc private func folderOptionsTapped(_ sender: UIButton) {
        let section = sender.tag
        let folderKey = sortedFolderKeys()[section]
        
        let optionSheet = UIAlertController(title: folderKey, message: nil, preferredStyle: .actionSheet)
        optionSheet.addAction(UIAlertAction(title: "Manage Files", style: .default, handler: { _ in
            // Present the folder management view controller.
            let manageVC = FolderManagementViewController()
            manageVC.folderName = folderKey
            // Provide the current notes so they can be managed.
            manageVC.notes = self.notes
            manageVC.onUpdate = { updatedNotes in
                // Update self.notes with changes from folder management.
                self.notes = updatedNotes
                self.tableView.reloadData()
            }
            let nav = UINavigationController(rootViewController: manageVC)
            self.present(nav, animated: true, completion: nil)
        }))
        
        optionSheet.addAction(UIAlertAction(title: "Delete Folder", style: .destructive, handler: { _ in
            // Remove folder and unassign notes.
            self.folders.removeAll { $0.name == folderKey }
            for i in 0..<self.notes.count {
                if self.notes[i].folder == folderKey {
                    self.notes[i].folder = nil
                }
            }
            self.tableView.reloadData()
        }))
        
        optionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // For iPad support.
        optionSheet.popoverPresentationController?.sourceView = sender
        optionSheet.popoverPresentationController?.sourceRect = sender.bounds
        
        self.present(optionSheet, animated: true, completion: nil)
    }
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
//        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
//        let key = sortedFolderKeys()[indexPath.section]
//        if let notesInFolder = groupedNotes()[key] {
//            let note = notesInFolder[indexPath.row]
//            cell.textLabel?.text = note.title
//        }
//        return cell
//    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        let key = sortedFolderKeys()[indexPath.section]
        if editingStyle == .delete, var notesInFolder = groupedNotes()[key] {
            let deletedNote = notesInFolder.remove(at: indexPath.row)
            if let originalIndex = notes.firstIndex(where: { $0.creationDate == deletedNote.creationDate }) {
                notes.remove(at: originalIndex)
            }
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = sortedFolderKeys()[indexPath.section]
        guard let note = groupedNotes()[key]?[indexPath.row] else { return }
        let detailVC = NoteDetailViewController(note: note, noteIndex: indexPath.row)
        detailVC.onSave = { [weak self] updatedNote in
            guard let self = self else { return }
            if let idx = self.notes.firstIndex(where: { $0.creationDate == updatedNote.creationDate }) {
                // Preserve the original folder assignment.
                var noteToSave = updatedNote
                noteToSave.folder = self.notes[idx].folder
                self.notes[idx] = noteToSave
            }
            self.notes.sort(by: { $0.creationDate > $1.creationDate })
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UITableViewDropDelegate
extension NotesViewController: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UIDropProposal {
        if destinationIndexPath != nil {
            // Returning .copy causes a "+" to appear on the drop location.
            return UIDropProposal(operation: .copy)
        }
        return UIDropProposal(operation: .cancel)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        if let destinationIndexPath = coordinator.destinationIndexPath {
            let folderKey = sortedFolderKeys()[destinationIndexPath.section]
            coordinator.session.loadObjects(ofClass: NSString.self) { _ in
                for item in coordinator.items {
                    if let note = item.dragItem.localObject as? Note {
                        var updatedNote = note
                        updatedNote.folder = folderKey == "Uncategorized" ? nil : folderKey
                        if let index = self.notes.firstIndex(where: { $0.creationDate == note.creationDate }) {
                            self.notes[index] = updatedNote
                        }
                    }
                }
                tableView.reloadData()
            }
        }
    }
}

// MARK: - UITableViewDragDelegate
extension NotesViewController: UITableViewDragDelegate {
    @objc func tableView(_ tableView: UITableView,
                         itemsForBeginning session: UIDragSession,
                         at indexPath: IndexPath) -> [UIDragItem] {
        let key = sortedFolderKeys()[indexPath.section]
        guard let notesInFolder = groupedNotes()[key] else { return [] }
        let note = notesInFolder[indexPath.row]
        let itemProvider = NSItemProvider(object: note.title as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = note
        return [dragItem]
    }
}

// MARK: - UISearchResultsUpdating
extension NotesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterNotes(for: searchController.searchBar.text)
    }
    
    private func filterNotes(for searchText: String?) {
        guard let text = searchText, !text.isEmpty else {
            filteredNotes = []
            tableView.reloadData()
            return
        }
        filteredNotes = notes.filter { note in
            note.title.lowercased().contains(text.lowercased())
        }
        tableView.reloadData()
    }
}