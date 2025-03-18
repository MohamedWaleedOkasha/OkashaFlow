import UIKit

class NoteDetailViewController: UIViewController {
    
    var note: Note
    var noteIndex: Int
    var onSave: ((Note) -> Void)?
    
    private let titleTextField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 24, weight: .bold)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.placeholder = "Title"
        return tf
    }()
    
    private let contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 18)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    init(note: Note, noteIndex: Int) {
        self.note = note
        self.noteIndex = noteIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Note"
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveNote))
        setupUI()
        titleTextField.text = note.title
        contentTextView.text = note.content
    }
    
    private func setupUI() {
        view.addSubview(titleTextField)
        view.addSubview(contentTextView)
        
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func saveNote() {
        let updatedTitle = titleTextField.text?.isEmpty == false ? titleTextField.text! : "Untitled Note"
        let updatedContent = contentTextView.text ?? ""
        // Preserve the original creation date so sorting remains consistent.
        note = Note(title: updatedTitle, content: updatedContent, creationDate: note.creationDate)
        onSave?(note)
        navigationController?.popViewController(animated: true)
    }
}