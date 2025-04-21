import UIKit
import UserNotifications

class CalendarDayCell: UICollectionViewCell {
    
    let dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    
    // Small circle indicator.
    let indicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        view.layer.cornerRadius = 3 // half of width/height to make it circular
        return view
    }()
    
    // Emoji label (e.g., gym emoji).
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dayLabel)
        contentView.addSubview(indicatorView)
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            indicatorView.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 2),
            indicatorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 6),
            indicatorView.heightAnchor.constraint(equalToConstant: 6),
            
            emojiLabel.topAnchor.constraint(equalTo: indicatorView.bottomAnchor, constant: 2),
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Make the cell circular by setting cornerRadius to half of the width
        layer.cornerRadius = bounds.width / 2
        // Ensure the cell maintains its circular shape
        clipsToBounds = true
    }
    
    private func scheduleCalendarNotification(for day: CalendarTask) {
        // Generate a unique ID for the notification
        let notificationId = UUID().uuidString 
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Calendar Event"
        content.body = "You have tasks due on \(day.date)."
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        // Set the trigger for the notification
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: day.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create the notification request
        let request = UNNotificationRequest(identifier: "calendar_\(notificationId)", content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
