import UIKit

struct Note: Codable {
    var title: String
    var content: String
    var creationDate: Date
}

class NotesViewController: UIViewController {
    
    private let notesKey = "notesKey"
    private var notes: [Note] = [] {
        didSet {
            saveNotes()
        }
    }
    
    // New property to hold search results
    private var filteredNotes: [Note] = []
    
    // Search controller to filter notes
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
        return tv
    }()
    
    // A computed property to check whether search is active and text not empty.
    private var isFiltering: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notes"
        view.backgroundColor = .systemBackground
        
        // Setup searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Notes"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addNote))
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadNotes()
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let savedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            // Order from newest to oldest
            notes = savedNotes.sorted(by: { $0.creationDate > $1.creationDate })
        }
    }
    
    private func saveNotes() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: notesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    @objc private func addNote() {
        // Create a new note with a default title
        let newNote = Note(title: "New Note", content: "", creationDate: Date())
        // Insert new note as the first one (newest)
        notes.insert(newNote, at: 0)
        tableView.reloadData()
        
        // Open detail view for editing
        let detailVC = NoteDetailViewController(note: newNote, noteIndex: 0)
        detailVC.onSave = { [weak self] updatedNote in
            guard let self = self else { return }
            self.notes[0] = updatedNote
            // Re-sort if needed
            self.notes.sort(by: { $0.creationDate > $1.creationDate })
            self.tableView.reloadData()
        }
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension NotesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return isFiltering ? filteredNotes.count : notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
         let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
         let note = isFiltering ? filteredNotes[indexPath.row] : notes[indexPath.row]
         cell.textLabel?.text = note.title
         return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let selectedNote = isFiltering ? filteredNotes[indexPath.row] : notes[indexPath.row]
         let detailVC = NoteDetailViewController(note: selectedNote, noteIndex: indexPath.row)
         detailVC.onSave = { [weak self] updatedNote in
             guard let self = self else { return }
             if self.isFiltering {
                 // Find the correct index in the primary array and update
                 if let originalIndex = self.notes.firstIndex(where: { $0.creationDate == selectedNote.creationDate }) {
                     self.notes[originalIndex] = updatedNote
                 }
             } else {
                 self.notes[indexPath.row] = updatedNote
             }
             // Re-sort to ensure newest first
             self.notes.sort(by: { $0.creationDate > $1.creationDate })
             self.tableView.reloadData()
         }
         navigationController?.pushViewController(detailVC, animated: true)
    }
}

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
            // Filtering based on note title; you can extend this to filter content, date, etc.
            return note.title.lowercased().contains(text.lowercased())
        }
        tableView.reloadData()
    }
}