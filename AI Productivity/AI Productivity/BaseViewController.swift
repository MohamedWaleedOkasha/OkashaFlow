import UIKit
class BaseViewController: UIViewController {
    private let backgroundColorKey = "selectedBackgroundColor"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the default background color for both light and dark mode
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        
        // Add observer for background color changes
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleBackgroundColorChange(_:)),
                                            name: .backgroundColorChanged,
                                            object: nil)
        
        // Load saved background color
        loadSavedBackgroundColor()
    }
    
    private func loadSavedBackgroundColor() {
        if let colorData = UserDefaults.standard.data(forKey: backgroundColorKey) {
            do {
                if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                    applyBackgroundColor(color)
                }
            } catch {
                print("Error unarchiving color: \(error)")
            }
        }
    }
    
    @objc private func handleBackgroundColorChange(_ notification: Notification) {
        if let color = notification.object as? UIColor {
            applyBackgroundColor(color)
        }
    }
    
    private func applyBackgroundColor(_ color: UIColor) {
        view.backgroundColor = color
        
        // Ensure this runs on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.view.subviews.forEach { subview in
                // Only clear background colors for views that don't need specific backgrounds
                if !(subview is UITextField) && 
                   !(subview is UIButton) && 
                   !(subview is UIDatePicker) {
                    subview.backgroundColor = .clear
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reapply the background color when the view appears
        if let colorData = UserDefaults.standard.data(forKey: backgroundColorKey) {
            do {
                if let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                    applyBackgroundColor(color)
                }
            } catch {
                print("Error unarchiving color: \(error)")
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Reapply the background color when switching between light/dark mode
        loadSavedBackgroundColor()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
