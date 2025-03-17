import UIKit
import UserNotifications

class CalendarDayCell: UICollectionViewCell {
    
    let dayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dayLabel)
        NSLayoutConstraint.activate([
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
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
