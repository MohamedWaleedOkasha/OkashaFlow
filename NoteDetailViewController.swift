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
    
    // A vertical stack view that will hold one voice memo bar view per memo.
    private let voiceMemoStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // AVFoundation properties for recording and playback.
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    // --------------------------
    // Initializers
    // init(note: Note, noteIndex: Int) {
    //     self.note = note
    //     self.noteIndex = noteIndex
    //     // If your Note model already supports multiple memos, you can parse them here.
    //     if let urls = note.voiceMemoURLs { // assume Note.voiceMemoURLs is [String]?
    //         self.voiceMemoURLs = urls.compactMap { URL(string: $0) }
    //     }
    //     super.init(nibName: nil, bundle: nil)
    // }
    
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
}
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // --------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Note"
        
        // Add the record button in the top-right of the navigation bar.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Record", style: .plain, target: self, action: #selector(recordVoiceMemoTapped))
        
        setupUI()
        titleTextField.text = note.title
        contentTextView.text = note.content
        
        // If voice memos exist, add them; otherwise add one invisible dummy view
        if voiceMemoURLs.isEmpty {
            let dummyBar = UIView()
            dummyBar.translatesAutoresizingMaskIntoConstraints = false
            // Give dummy bar the same height as a voice memo bar.
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
    
    private func setupUI() {
        view.addSubview(voiceMemoStackView)
        view.addSubview(titleTextField)
        view.addSubview(contentTextView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Voice memo stack view stretches across the full safe area width.
            voiceMemoStackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            voiceMemoStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            voiceMemoStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            
            // Title text field placed below the voice memo stack view with padding.
            titleTextField.topAnchor.constraint(equalTo: voiceMemoStackView.bottomAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            
            // Content text view fills the remaining space with padding.
            contentTextView.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            contentTextView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveNote()
    }
    
    @objc private func saveNote() {
        let updatedTitle = titleTextField.text?.isEmpty == false ? titleTextField.text! : "Untitled Note"
        let updatedContent = contentTextView.text ?? ""
        // Convert voiceMemoURLs to an array of String.
        let urlsAsString = voiceMemoURLs.map { $0.absoluteString }
        note = Note(title: updatedTitle, content: updatedContent, creationDate: note.creationDate, voiceMemoURLs: urlsAsString)
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
                // Unhide the stack view when adding a new memo.
                voiceMemoStackView.isHidden = false
            }
        }
        isRecording.toggle()
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
    
    // Helper: Create a voice memo bar view representing one voice memo.
    private func createVoiceMemoBar(for url: URL) -> UIView {
        let barView = UIView()
        barView.translatesAutoresizingMaskIntoConstraints = false
        barView.backgroundColor = UIColor.systemGray5
        barView.layer.cornerRadius = 8

        // Play/Pause button on the far left.
        let playButton = UIButton(type: .system)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.translatesAutoresizingMaskIntoConstraints = false

        // Delete button.
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        // Duration label.
        let durationLabel = UILabel()
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.textColor = .label
        durationLabel.font = UIFont.systemFont(ofSize: 16)
        durationLabel.textAlignment = .right

        // Progress bar that stretches between the play button and the duration label.
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0.0
        // Set an identifier for later lookup.
        progressView.accessibilityIdentifier = "progressView"

        barView.addSubview(playButton)
        barView.addSubview(progressView)
        barView.addSubview(durationLabel)
        barView.addSubview(deleteButton)

        // Set constraints.
        NSLayoutConstraint.activate([
            barView.heightAnchor.constraint(equalToConstant: 40),

            // Play button on far left.
            playButton.leadingAnchor.constraint(equalTo: barView.leadingAnchor, constant: 8),
            playButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30),

            // Duration label on right.
            durationLabel.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            durationLabel.widthAnchor.constraint(equalToConstant: 60),

            // Delete button on far right.
            deleteButton.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: barView.trailingAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),

            // Progress view between play button and duration label.
            progressView.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            progressView.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8)
        ])

        // Set the duration label text.
        let asset = AVURLAsset(url: url)
        let totalSeconds = Int(asset.duration.seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        durationLabel.text = String(format: "%02d:%02d", minutes, seconds)

        // Action for play/pause.
        playButton.addTarget(self, action: #selector(voiceMemoBarPlayTapped(_:)), for: .touchUpInside)
        playButton.tag = voiceMemoStackView.arrangedSubviews.count  // simple tag to identify (if needed)
        // Store the URL with the button via accessibilityHint for simplicity.
        playButton.accessibilityHint = url.absoluteString

        // Action for delete.
        deleteButton.addTarget(self, action: #selector(deleteVoiceMemoTapped(_:)), for: .touchUpInside)
        deleteButton.accessibilityHint = url.absoluteString

        return barView
    }
    
    // Helper: Create a view that simulates sound lines for the given voice memo.
    // In this simple demo we generate a few random bar heights.
    private func createSoundLinesView(for url: URL) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 2
        
        // Generate 5 bars with random heights (simulate amplitude).
        for _ in 0..<5 {
            let bar = UIView()
            bar.backgroundColor = .systemBlue
            let randomHeight = CGFloat(arc4random_uniform(20) + 10) // between 10 and 30
            bar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bar.widthAnchor.constraint(equalToConstant: 3),
                bar.heightAnchor.constraint(equalToConstant: randomHeight)
            ])
            container.addArrangedSubview(bar)
        }
        return container
    }
    
    @objc private func voiceMemoBarPlayTapped(_ sender: UIButton) {
        // Retrieve the URL from sender.accessibilityHint.
        guard let urlString = sender.accessibilityHint, let url = URL(string: urlString) else { return }
        // Retrieve the progress view by finding the subview with the matching identifier.
        guard let barView = sender.superview,
              let progressView = barView.subviews.first(where: { ($0 as? UIProgressView)?.accessibilityIdentifier == "progressView" }) as? UIProgressView else { return }
        do {
            // Toggle play/pause for this voice memo.
            if let player = audioPlayer, player.isPlaying, player.url == url {
                player.pause()
                sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
                progressTimer?.invalidate()
                progressTimer = nil
            } else {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                // Set up timer to update progress.
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
        guard let urlString = sender.accessibilityHint, let url = URL(string: urlString) else { return }
        // Remove from the data model.
        if let index = voiceMemoURLs.firstIndex(where: { $0.absoluteString == urlString }) {
            voiceMemoURLs.remove(at: index)
        }
        // Remove the corresponding bar view from the stack.
        // (Assume the structure: the delete button is inside the bar view.)
        if let barView = sender.superview {
            voiceMemoStackView.removeArrangedSubview(barView)
            barView.removeFromSuperview()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension NoteDetailViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
