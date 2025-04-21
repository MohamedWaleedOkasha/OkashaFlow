import UIKit

class FolderManagementViewController: UIViewController {

    var folderName: String!
    // The notes to display & update.
    var notes: [Note] = []
    // Callback after updating membership.
    var onUpdate: (([Note]) -> Void)?
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "ManageNoteCell")
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Manage Files (\(folderName!))"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc private func doneTapped() {
        onUpdate?(notes)
        dismiss(animated: true, completion: nil)
    }
}

extension FolderManagementViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = notes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ManageNoteCell", for: indexPath)
        
        // If the note is assigned to a folder different than the current management folder,
        // display file_name(other_folder)
        if let assignedFolder = note.folder, assignedFolder != folderName {
            cell.textLabel?.text = "\(note.title)(\(assignedFolder))"
        } else {
            cell.textLabel?.text = note.title
        }
        // Show a checkmark if the note is assigned to this folder.
        cell.accessoryType = (note.folder == folderName) ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Toggle the note's membership in this folder.
        var note = notes[indexPath.row]
        if note.folder == folderName {
            // Remove note from folder
            note.folder = nil
        } else {
            // Assign note to this folder
            note.folder = folderName
        }
        notes[indexPath.row] = note
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}