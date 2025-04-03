import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class LoginViewController: UIViewController {
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Login Here"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1) // Similar color to SignUp
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1) // Similar color to SignUp
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let createAccountLabel: UILabel = {
        let label = UILabel()
        label.text = "Don't have an account?"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let createAccountButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create Account", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let loginWithLabel: UILabel = {
        let label = UILabel()
        label.text = "Login with"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let googleLoginButton: UIButton = {
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
        title = "Log In"
        
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(createAccountLabel)
        view.addSubview(createAccountButton)
        view.addSubview(loginWithLabel)
        view.addSubview(googleLoginButton)
        
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
            
            // Login Button constraints
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 40),
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 200),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Create Account Label constraints
            createAccountLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            createAccountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Create Account Button constraints
            createAccountButton.topAnchor.constraint(equalTo: createAccountLabel.bottomAnchor, constant: 8),
            createAccountButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Login With Label constraints
            loginWithLabel.topAnchor.constraint(equalTo: createAccountButton.bottomAnchor, constant: 40),
            loginWithLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Google Login Button constraints
            googleLoginButton.topAnchor.constraint(equalTo: loginWithLabel.bottomAnchor, constant: 20),
            googleLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleLoginButton.widthAnchor.constraint(equalToConstant: 100),
            googleLoginButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        createAccountButton.addTarget(self, action: #selector(createAccountTapped), for: .touchUpInside)
        googleLoginButton.addTarget(self, action: #selector(googleLoginTapped), for: .touchUpInside)
    }
    
    @objc private func loginTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.showAlert(message: error.localizedDescription)
                return
            }
            
            if let user = result?.user {
                self?.goToHomeScreen()
            }
        }
    }
    
    @objc private func createAccountTapped() {
        let signUpVC = SignUpViewController()
        signUpVC.modalPresentationStyle = .fullScreen
        present(signUpVC, animated: true)
    }
    
    @objc private func googleLoginTapped() {
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
                    self?.goToHomeScreen()
                }
            }
        }
    }
    
    // private func goToHomeScreen() {
    //     let homeVC = HomeScreenViewController()
    //     let navController = UINavigationController(rootViewController: homeVC)
    //     navController.modalPresentationStyle = .fullScreen
    //     present(navController, animated: true)
    // }
    private func goToHomeScreen() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else { return }
    window.rootViewController = MainTabBarController()
    UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}