import UIKit
import AVFoundation
import AudioToolbox
import UserNotifications
import BackgroundTasks

enum PomodoroMode: Int {
    case focus = 0
    case shortBreak = 1
    case longBreak = 2
}

class PomodoroViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sessionProgressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.text = "Session 0/4"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let startPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Customization Sliders
    private let focusDurationSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 15 * 60  // 15 min
        slider.maximumValue = 60 * 60  // 60 min
        slider.value = 25 * 60         // default 25 min
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let breakDurationSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 3 * 60   // 3 min
        slider.maximumValue = 30 * 60  // 30 min
        slider.value = 5 * 60          // default 5 min for short break
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let focusDurationLabel: UILabel = {
        let label = UILabel()
        label.text = "Focus: 25 min"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let breakDurationLabel: UILabel = {
        let label = UILabel()
        label.text = "Break: 5 min"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Timer & Mode Properties
    private var timer: Timer?
    private var remainingSeconds: Int = 25 * 60
    private var isTimerRunning = false
    private var mode: PomodoroMode = .focus
    private var sessionCount = 0
    
    // Customizable durations
    private var focusDuration: Int {
        return Int(focusDurationSlider.value)
    }
    private var shortBreakDuration: Int {
        return Int(breakDurationSlider.value)
    }
    private var longBreakDuration: Int {
        return Int(breakDurationSlider.value) * 3
    }
    
    // Audio & Haptics
    private var audioPlayer: AVAudioPlayer?
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Properties
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var timerEndDate: Date?
    private var savedRemainingSeconds: Int?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Focus Mode"
        
        // Activate audio session for background audio
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
        
        setupUI()
        updateTimerLabel()
        updateSessionProgress()
        feedbackGenerator.prepare()
        setupNotifications()
        setupBackgroundTask()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreTimerState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveTimerState()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Add subviews
        view.addSubview(timerLabel)
        view.addSubview(sessionProgressLabel)
        view.addSubview(startPauseButton)
        view.addSubview(resetButton)
        view.addSubview(focusDurationLabel)
        view.addSubview(focusDurationSlider)
        view.addSubview(breakDurationLabel)
        view.addSubview(breakDurationSlider)
        
        // Button Targets
        startPauseButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        focusDurationSlider.addTarget(self, action: #selector(focusSliderChanged(_:)), for: .valueChanged)
        breakDurationSlider.addTarget(self, action: #selector(breakSliderChanged(_:)), for: .valueChanged)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            sessionProgressLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 10),
            sessionProgressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            startPauseButton.topAnchor.constraint(equalTo: sessionProgressLabel.bottomAnchor, constant: 20),
            startPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            resetButton.topAnchor.constraint(equalTo: startPauseButton.bottomAnchor, constant: 10),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            focusDurationLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 20),
            focusDurationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            focusDurationSlider.topAnchor.constraint(equalTo: focusDurationLabel.bottomAnchor, constant: 5),
            focusDurationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            focusDurationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            breakDurationLabel.topAnchor.constraint(equalTo: focusDurationSlider.bottomAnchor, constant: 20),
            breakDurationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            breakDurationSlider.topAnchor.constraint(equalTo: breakDurationLabel.bottomAnchor, constant: 5),
            breakDurationSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            breakDurationSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Timer Update Methods
    private func updateTimerLabel() {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateSessionProgress() {
        sessionProgressLabel.text = "Session \(sessionCount)/4"
    }
    
    @objc private func startPauseTapped() {
        if isTimerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    @objc private func resetTapped() {
        pauseTimer()
        switch mode {
        case .focus:
            remainingSeconds = focusDuration
        case .shortBreak:
            remainingSeconds = shortBreakDuration
        case .longBreak:
            remainingSeconds = longBreakDuration
        }
        updateTimerLabel()
    }
    
    private func startTimer() {
        isTimerRunning = true
        startPauseButton.setTitle("Pause", for: .normal)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        playWhiteNoise()
    }
    
    private func pauseTimer() {
        isTimerRunning = false
        startPauseButton.setTitle("Start", for: .normal)
        timer?.invalidate()
        timer = nil
        timerEndDate = nil
        audioPlayer?.pause()
    }
    
    @objc private func timerFired() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            updateTimerLabel()
        } else {
            timer?.invalidate()
            timer = nil
            isTimerRunning = false
            audioPlayer?.stop() // Stop any white noise
            feedbackGenerator.notificationOccurred(.success)
            playAlertSound()  // Start alarm sound

            // Update Pomodoro stats if session ended
            if mode == .focus {
                updatePomodoroStats()
            }
            
            // Transition to next mode
            if mode == .focus {
                sessionCount += 1
                if sessionCount % 4 == 0 {
                    mode = .longBreak
                    remainingSeconds = longBreakDuration
                } else {
                    mode = .shortBreak
                    remainingSeconds = shortBreakDuration
                }
            } else {
                mode = .focus
                remainingSeconds = focusDuration
            }
            updateSessionProgress()
            updateTimerLabel()

            let modeName = (mode == .focus) ? "Focus" : (mode == .shortBreak ? "Short Break" : "Long Break")
            let alert = UIAlertController(title: "Session Complete", message: "Starting \(modeName) session.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Stop Alarm", style: .default, handler: { _ in
                self.audioPlayer?.stop()
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.audioPlayer?.stop()
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Audio & Haptics
    private func playWhiteNoise() {
        guard let url = Bundle.main.url(forResource: "white_noise", withExtension: "mp3") else {
            print("White noise file not found.")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            print("Error playing white noise: \(error.localizedDescription)")
        }
    }
    
    private func playAlertSound() {
        guard let alertUrl = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            // Fallback to system sound if alarm file not found
            AudioServicesPlaySystemSound(1005)
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: alertUrl)
            audioPlayer?.numberOfLoops = -1   // Loop alarm indefinitely
            audioPlayer?.play()
        } catch {
            print("Error playing alarm sound: \(error.localizedDescription)")
            AudioServicesPlaySystemSound(1005)
        }
    }
    
    // MARK: - Customization Slider Actions
    @objc private func focusSliderChanged(_ sender: UISlider) {
        let minutes = Int(sender.value) / 60
        focusDurationLabel.text = "Focus: \(minutes) min"
        if mode == .focus && !isTimerRunning {
            remainingSeconds = Int(sender.value)
            updateTimerLabel()
        }
    }
    
    @objc private func breakSliderChanged(_ sender: UISlider) {
        let minutes = Int(sender.value) / 60
        breakDurationLabel.text = "Break: \(minutes) min"
        if (mode == .shortBreak || mode == .longBreak) && !isTimerRunning {
            remainingSeconds = Int(sender.value)
            updateTimerLabel()
        }
    }
    
    // MARK: - Footer Button Actions (Stubbed)
    @objc private func addTodoTapped() {
        let addTaskVC = AddTaskViewController()
        if let nav = self.navigationController {
            nav.pushViewController(addTaskVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: addTaskVC)
            present(nav, animated: true, completion: nil)
        }
    }
    
    @objc private func aiChatTapped() {
        print("Navigating to AI Chat...")
        // Implement AI Chat navigation here.
    }
    
    @objc private func addCalendarTapped() {
        print("Add Calendar event tapped!")
        // Implement calendar event creation here.
    }
    
    // MARK: - Background Task & Notifications
    private func setupBackgroundTask() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundTransition), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForegroundTransition), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func handleBackgroundTransition() {
        if isTimerRunning {
            startBackgroundTask()
            scheduleTimerCompletionNotification()
        }
    }
    
    @objc private func handleForegroundTransition() {
        if backgroundTask != .invalid {
            endBackgroundTask()
        }
        restoreTimerState()
    }
    
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        if backgroundTask != .invalid {
            UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func scheduleTimerCompletionNotification() {
        guard let endDate = timerEndDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete"
        content.body = "Your \(mode == .focus ? "Focus" : "Break") session has ended"
        content.sound = UNNotificationSound.default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate), repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func saveTimerState() {
        if isTimerRunning {
            UserDefaults.standard.set(remainingSeconds, forKey: "savedRemainingSeconds")
            UserDefaults.standard.set(Date().addingTimeInterval(TimeInterval(remainingSeconds)), forKey: "timerEndDate")
            UserDefaults.standard.set(mode.rawValue, forKey: "savedMode")
            UserDefaults.standard.set(sessionCount, forKey: "savedSessionCount")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func restoreTimerState() {
        if let savedSeconds = UserDefaults.standard.object(forKey: "savedRemainingSeconds") as? Int,
           let endDate = UserDefaults.standard.object(forKey: "timerEndDate") as? Date,
           let savedModeRaw = UserDefaults.standard.object(forKey: "savedMode") as? Int,
           let savedMode = PomodoroMode(rawValue: savedModeRaw) {
            
            let timeElapsed = Int(Date().timeIntervalSince(endDate))
            remainingSeconds = max(0, savedSeconds - timeElapsed)
            mode = savedMode
            sessionCount = UserDefaults.standard.integer(forKey: "savedSessionCount")
            
            updateTimerLabel()
            updateSessionProgress()
            
            if remainingSeconds > 0 {
                startTimer()
            } else {
                timerFired()
            }
        }
    }
    
    // MARK: - Statistics
    private func updatePomodoroStats() {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current
        
        // Update today's count
        let todayKey = "pomodoroToday"
        let todayCount = defaults.integer(forKey: todayKey)
        defaults.set(todayCount + 1, forKey: todayKey)
        
        // Update this week's count
        let weekKey = "pomodoroThisWeek"
        let weekCount = defaults.integer(forKey: weekKey)
        defaults.set(weekCount + 1, forKey: weekKey)
        
        // Update total count
        let totalKey = "pomodoroTotal"
        let totalCount = defaults.integer(forKey: totalKey)
        defaults.set(totalCount + 1, forKey: totalKey)
        
        // Reset daily count if it's a new day
        if let lastDate = defaults.object(forKey: "lastPomodoroDate") as? Date,
           !calendar.isDateInToday(lastDate) {
            defaults.set(0, forKey: todayKey)
        }
        
        // Reset weekly count if it's a new week
        if let lastDate = defaults.object(forKey: "lastPomodoroDate") as? Date,
           !calendar.isDate(lastDate, equalTo: Date(), toGranularity: .weekOfYear) {
               defaults.set(0, forKey: weekKey)
           }
    
        // Update last date
        defaults.set(Date(), forKey: "lastPomodoroDate")
        defaults.synchronize()
    }
}
