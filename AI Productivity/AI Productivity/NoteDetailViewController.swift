import UIKit
import AVFoundation

class NoteDetailViewController: UIViewController {
    
    var note: Note
    var noteIndex: Int
    var onSave: ((Note) -> Void)?
    
    // Instead of a single voice memo URL, support multiple memos.
    var voiceMemoURLs: [URL] = []
    
    // Flag to track recording state.
    var isRecording = false
    
    // Add a property to manage the timer:
    var progressTimer: Timer?
    
    // Add this new property below your other properties:
    private var noteImagePath: String?
    
    // MARK: - UI Components
    
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
    
    // Image view to hold the chosen image.
    private let noteImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isHidden = true
        return iv
    }()
    // A constraint to manage the image view height.
    private var noteImageHeightConstraint: NSLayoutConstraint!
    
    // A vertical stack view that will hold one voice memo bar view per memo.
    private let voiceMemoStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // Bottom bar with mic and camera buttons.
    private let bottomBar: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .systemBackground
        return v
    }()
    
    private let micButton: UIButton = {
       let button = UIButton(type: .system)
       button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
       button.translatesAutoresizingMaskIntoConstraints = false
       return button
    }()
    
    private let cameraButton: UIButton = {
       let button = UIButton(type: .system)
       button.setImage(UIImage(systemName: "camera.fill"), for: .normal)
       button.translatesAutoresizingMaskIntoConstraints = false
       return button
    }()
    
    // AVFoundation properties for recording and playback.
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    // --------------------------
    // Initializers
    init(note: Note, noteIndex: Int) {
        self.note = note
        self.noteIndex = noteIndex
        // Convert each optional string to a URL.
        self.voiceMemoURLs = note.voiceMemoURLs.compactMap { str in
            if let s = str {
                return URL(string: s)
            }
            return nil
        }
        super.init(nibName: nil, bundle: nil)
        // Ensure the tab bar is hidden when pushed.
        self.hidesBottomBarWhenPushed = true
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Note"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Record", style: .plain, target: self, action: #selector(recordVoiceMemoTapped))
        
        setupUI()
        titleTextField.text = note.title
        contentTextView.text = note.content
        
        // Load the persisted image if exists.
        if let imagePath = note.imagePath {
            let fileURL = getDocumentsDirectory().appendingPathComponent(imagePath)
            if let image = UIImage(contentsOfFile: fileURL.path) {
                noteImageView.image = image
                noteImageView.isHidden = false
                noteImageHeightConstraint.constant = 200
            }
        }
        
        // Voice memos setup…
        if voiceMemoURLs.isEmpty {
            let dummyBar = UIView()
            dummyBar.translatesAutoresizingMaskIntoConstraints = false
            dummyBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
            dummyBar.isHidden = true
            voiceMemoStackView.addArrangedSubview(dummyBar)
        } else {
            voiceMemoStackView.isHidden = false
            for url in voiceMemoURLs {
                let bar = createVoiceMemoBar(for: url)
                voiceMemoStackView.addArrangedSubview(bar)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the tabBar when this view appears.
        tabBarController?.tabBar.isHidden = true
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        // Optionally, restore the tab bar if needed.
//        // Note: This might be omitted if the next pushed view controller also hides it.
//        tabBarController?.tabBar.isHidden = false
//    }
    
    private func setupUI() {
        view.addSubview(voiceMemoStackView)
        view.addSubview(titleTextField)
        view.addSubview(noteImageView)
        view.addSubview(contentTextView)
        view.addSubview(bottomBar)
        
        // Add mic and camera buttons to the bottom bar.
        bottomBar.addSubview(micButton)
        bottomBar.addSubview(cameraButton)
        
        // Set up the fixed height constraint for the image view.
        noteImageHeightConstraint = noteImageView.heightAnchor.constraint(equalToConstant: 0)
        noteImageHeightConstraint.isActive = true
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Voice memo stack view constraints.
            voiceMemoStackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            voiceMemoStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            voiceMemoStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            
            // Title text field.
            titleTextField.topAnchor.constraint(equalTo: voiceMemoStackView.bottomAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            
            // Note image view between title and content.
            noteImageView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 8),
            noteImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            noteImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            
            // Content text view above the bottom bar.
            contentTextView.topAnchor.constraint(equalTo: noteImageView.bottomAnchor, constant: 8),
            contentTextView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            contentTextView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            
            // Bottom bar constraints.
            bottomBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            micButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            micButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 30),
            micButton.widthAnchor.constraint(equalToConstant: 30),
            micButton.heightAnchor.constraint(equalToConstant: 30),
            
            cameraButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            cameraButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -30),
            cameraButton.widthAnchor.constraint(equalToConstant: 30),
            cameraButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        micButton.addTarget(self, action: #selector(micButtonTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveNote()
    }
    
    @objc private func saveNote() {
        // Save the image to disk if available.
        if let image = noteImageView.image, let data = image.jpegData(compressionQuality: 0.8) {
            let fileName = "noteImage_\(UUID().uuidString).jpg"
            let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                try data.write(to: fileURL)
                noteImagePath = fileName
            } catch {
                print("Error saving image: \(error)")
            }
        }
        
        let updatedTitle = titleTextField.text?.isEmpty == false ? titleTextField.text! : "Untitled Note"
        let updatedContent = contentTextView.text ?? ""
        let urlsAsString = voiceMemoURLs.map { $0.absoluteString }
        note = Note(title: updatedTitle,
                    content: updatedContent,
                    creationDate: note.creationDate,
                    voiceMemoURLs: urlsAsString,
                    imagePath: noteImagePath)
        onSave?(note)
    }
    
    // MARK: - Voice Memo Recording and Playback
    @objc private func recordVoiceMemoTapped() {
        if !isRecording {
            startRecording()
            navigationItem.rightBarButtonItem?.title = "End"
        } else {
            finishRecording(success: true)
            navigationItem.rightBarButtonItem?.title = "Record"
            if let url = voiceMemoURLTemporary {
                voiceMemoURLs.append(url)
                let bar = createVoiceMemoBar(for: url)
                voiceMemoStackView.addArrangedSubview(bar)
                voiceMemoStackView.isHidden = false
            }
        }
        isRecording.toggle()
    }
    
    @objc private func micButtonTapped() {
        recordVoiceMemoTapped()
    }
    
    // Temporary property to hold the memo being recorded.
    var voiceMemoURLTemporary: URL?
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let fileName = "voiceMemo_\(UUID().uuidString).m4a"
            let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
            voiceMemoURLTemporary = filePath
            audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
        } catch {
            finishRecording(success: false)
        }
    }
    
    private func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        if !success {
            navigationItem.rightBarButtonItem?.title = "Record"
        }
    }
    
    private func createVoiceMemoBar(for url: URL) -> UIView {
        let barView = UIView()
        barView.translatesAutoresizingMaskIntoConstraints = false
        barView.backgroundColor = UIColor.systemGray5
        barView.layer.cornerRadius = 8
        
        let playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        let durationLabel = UILabel()
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.textColor = .label
        durationLabel.font = UIFont.systemFont(ofSize: 16)
        durationLabel.textAlignment = .right
        
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0.0
        progressView.accessibilityIdentifier = "progressView"
        
        barView.addSubview(playButton)
        barView.addSubview(progressView)
        barView.addSubview(durationLabel)
        barView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            barView.heightAnchor.constraint(equalToConstant: 40),
            
            playButton.leadingAnchor.constraint(equalTo: barView.leadingAnchor, constant: 8),
            playButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30),
            
            durationLabel.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            durationLabel.widthAnchor.constraint(equalToConstant: 60),
            
            deleteButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: barView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            
            progressView.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8)
        ])
        
        let asset = AVURLAsset(url: url)
        let totalSeconds = Int(asset.duration.seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
        
        playButton.addTarget(self, action: #selector(voiceMemoBarPlayTapped(_:)), for: .touchUpInside)
        playButton.tag = voiceMemoStackView.arrangedSubviews.count
        playButton.accessibilityHint = url.absoluteString
        
        deleteButton.addTarget(self, action: #selector(deleteVoiceMemoTapped(_:)), for: .touchUpInside)
        deleteButton.accessibilityHint = url.absoluteString
        
        return barView
    }
    
    @objc private func voiceMemoBarPlayTapped(_ sender: UIButton) {
        guard let urlString = sender.accessibilityHint, let url = URL(string: urlString) else { return }
        guard let barView = sender.superview,
              let progressView = barView.subviews.first(where: { ($0 as? UIProgressView)?.accessibilityIdentifier == "progressView" }) as? UIProgressView else { return }
        do {
            if let player = audioPlayer, player.isPlaying, player.url == url {
                player.pause()
                sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
                progressTimer?.invalidate()
                progressTimer = nil
            } else {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                progressTimer?.invalidate()
                progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak progressView] timer in
                    guard let player = self?.audioPlayer else {
                        timer.invalidate()
                        return
                    }
                    progressView?.progress = Float(player.currentTime / player.duration)
                    if player.currentTime >= player.duration {
                        timer.invalidate()
                        sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
                    }
                }
            }
        } catch {
            print("Playback failed: \(error.localizedDescription)")
        }
    }
    
    @objc private func deleteVoiceMemoTapped(_ sender: UIButton) {
        guard let urlString = sender.accessibilityHint, let _ = URL(string: urlString) else { return }
        if let index = voiceMemoURLs.firstIndex(where: { $0.absoluteString == urlString }) {
            voiceMemoURLs.remove(at: index)
        }
        if let barView = sender.superview {
            voiceMemoStackView.removeArrangedSubview(barView)
            barView.removeFromSuperview()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    @objc private func cameraButtonTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        present(picker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension NoteDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            noteImageView.image = image
            noteImageView.isHidden = false
            noteImageHeightConstraint.constant = 200
            view.layoutIfNeeded()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - AVAudioRecorderDelegate
extension NoteDetailViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
