import UIKit
import FirebaseAuth

class AuthViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailField.text, let password = passwordField.text else { return }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            } else {
                self.navigateToHomeScreen()
            }
        }
    }

    @IBAction func signUpTapped(_ sender: UIButton) {
        guard let email = emailField.text, let password = passwordField.text else { return }

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign-up failed: \(error.localizedDescription)")
            } else {
                self.navigateToHomeScreen()
            }
        }
    }

    func navigateToHomeScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeScreen")
        homeVC.modalPresentationStyle = .fullScreen
        present(homeVC, animated: true)
    }
}
