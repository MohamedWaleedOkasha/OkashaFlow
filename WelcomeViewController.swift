import UIKit

class WelcomeViewController: UIViewController {
    
    // MARK: - UI Components
    private let welcomeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "welcome_image") // Make sure to add this image to your assets
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to OKSH"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 10/255, green: 5/255, blue: 163/255, alpha: 1) // Custom blue color
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "A simple and powerful way to stay productive every day"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0 // Allow multiple lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(welcomeImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        // Create a stack view for the buttons
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 20 // Space between buttons
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add buttons to the stack view
        buttonStackView.addArrangedSubview(signUpButton)
        buttonStackView.addArrangedSubview(loginButton)
        
        // Add the stack view to the main view
        view.addSubview(buttonStackView)
        
        // Set button colors
        // signUpButton.backgroundColor = .systemBlue // Blue for Sign Up
        loginButton.backgroundColor = .systemGray // Grey for Log In
        
        NSLayoutConstraint.activate([
            // Welcome Image constraints
            welcomeImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            welcomeImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            welcomeImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            welcomeImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35), // 35% of screen height
            
            // Title Label constraints
            titleLabel.topAnchor.constraint(equalTo: welcomeImageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Subtitle Label constraints
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Button Stack View constraints
            buttonStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            buttonStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Set fixed width and height for buttons
            signUpButton.widthAnchor.constraint(equalToConstant: 100),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.widthAnchor.constraint(equalToConstant: 100),
            loginButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(logInTapped), for: .touchUpInside)
    }
    
    @objc private func signUpTapped() {
        let signUpVC = SignUpViewController()
        signUpVC.modalPresentationStyle = .fullScreen
        present(signUpVC, animated: true)
    }
    
    @objc private func logInTapped() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
}
