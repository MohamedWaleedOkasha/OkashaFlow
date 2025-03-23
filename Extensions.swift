import UIKit

extension UIColor {
    var isDark: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Calculate brightness (perceived luminance)
        let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        return brightness < 0.5
    }
    
    var contrastColor: UIColor {
        return self.isDark ? .white : .black
    }
}