import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class CustomTextField: UITextField {
    // Custom UITextField to add padding
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5) // Increase padding
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 5) // Increase padding
    }
}

class SignUpViewController: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let confirmPasswordTextField: CustomTextField = {
        let textField = CustomTextField()
        textField.placeholder = "Confirm Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let alreadyHaveAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Already have an account?"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let continueWithLabel: UILabel = {
        let label = UILabel()
        label.text = "Or continue with"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let googleSignUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Add Google logo
        let googleLogo = UIImageView(image: UIImage(named: "google_logo"))
        googleLogo.contentMode = .scaleAspectFit
        googleLogo.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(googleLogo)
        
        // Set constraints for the Google logo
        NSLayoutConstraint.activate([
            googleLogo.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            googleLogo.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            googleLogo.widthAnchor.constraint(equalToConstant: 20),
            googleLogo.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(confirmPasswordTextField)
        view.addSubview(signUpButton)
        view.addSubview(alreadyHaveAccountLabel)
        view.addSubview(loginButton)
        view.addSubview(continueWithLabel)
        view.addSubview(googleSignUpButton)
        
        // Set background colors for text fields
        emailTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        passwordTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        confirmPasswordTextField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Title Label constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Email TextField constraints
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password TextField constraints
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Confirm Password TextField constraints
            confirmPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            confirmPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Sign Up Button constraints
            signUpButton.topAnchor.constraint(equalTo: confirmPasswordTextField.bottomAnchor, constant: 60),
            signUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signUpButton.widthAnchor.constraint(equalTo: emailTextField.widthAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Already Have Account Label constraints
            alreadyHaveAccountLabel.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 20),
            alreadyHaveAccountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Login Button constraints
            loginButton.topAnchor.constraint(equalTo: alreadyHaveAccountLabel.bottomAnchor, constant: 8),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Continue With Label constraints
            continueWithLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 40),
            continueWithLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Google Sign Up Button constraints
            googleSignUpButton.topAnchor.constraint(equalTo: continueWithLabel.bottomAnchor, constant: 20),
            googleSignUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleSignUpButton.widthAnchor.constraint(equalToConstant: 100), // Adjusted size
            googleSignUpButton.heightAnchor.constraint(equalToConstant: 40) // Adjusted size
        ])
        
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(logInTapped), for: .touchUpInside)
        googleSignUpButton.addTarget(self, action: #selector(googleSignUpTapped), for: .touchUpInside)
    }
    
    @objc private func signUpTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text, !confirmPassword.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(message: "Passwords do not match")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.showAlert(message: error.localizedDescription)
                return
            }
            
            if let user = result?.user {
                self?.goToUserProfileCreation()
            }
        }
    }
    
    @objc private func logInTapped() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
    
    @objc private func googleSignUpTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            if let error = error {
                self?.showAlert(message: error.localizedDescription)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    self?.showAlert(message: error.localizedDescription)
                    return
                }
                
                if let user = result?.user {
                    self?.goToUserProfileCreation()
                }
            }
        }
    }
    
    private func goToUserProfileCreation() {
        let profileVC = UserProfileCreationViewController()
        profileVC.modalPresentationStyle = .fullScreen
        present(profileVC, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
