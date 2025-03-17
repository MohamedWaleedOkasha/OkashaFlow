import UIKit
import FirebaseAuth
import FirebaseStorage

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.layer.cornerRadius = 50
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let changePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change Photo", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Changes", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Profile"
        setupUI()
        loadUserProfile()
    }
    
    private func setupUI() {
        view.addSubview(profileImageView)
        view.addSubview(changePhotoButton)
        view.addSubview(nameTextField)
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            changePhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            changePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nameTextField.topAnchor.constraint(equalTo: changePhotoButton.bottomAnchor, constant: 32),
            nameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 32),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveChangesTapped), for: .touchUpInside)
    }
    
    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            nameTextField.text = profile.name
            
            if let imageURL = profile.profileImageURL {
                loadProfileImage(from: imageURL)
            }
        }
    }
    
    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
    }
    
    @objc private func changePhotoTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    @objc private func saveChangesTapped() {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(message: "Please enter your name")
            return
        }
        
        // If there's a new image that hasn't been uploaded yet
        if let image = profileImageView.image {
            uploadImage(image) { [weak self] imageURL in
                self?.saveProfile(name: name, imageURL: imageURL)
            }
        } else {
            // If no new image, just save the name
            saveProfile(name: name, imageURL: nil)
        }
    }
    
    private func uploadImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            DispatchQueue.main.async {
                self.showAlert(message: "Failed to process image")
            }
            completion(nil)
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.showAlert(message: "User not authenticated")
            }
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("profile_images").child("\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "Uploading image...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        DispatchQueue.main.async {
            self.present(loadingAlert, animated: true, completion: nil)
        }

        // Upload the image
        imageRef.putData(imageData, metadata: metadata) { [weak self] metadata, error in
            // Dismiss loading indicator
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true)
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(message: "Upload failed: \(error.localizedDescription)")
                }
                completion(nil)
                return
            }
            
            // Get download URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showAlert(message: "Failed to get download URL: \(error.localizedDescription)")
                    }
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }
    
    private func saveProfile(name: String, imageURL: String?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(message: "User not authenticated")
            return
        }
        
        // Get existing profile data to preserve any other fields
        var age: Int? = nil
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let existingProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            age = existingProfile.age
        }
        
        let profile = UserProfile(name: name, age: age, profileImageURL: imageURL, userId: userId)
        
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
            UserDefaults.standard.synchronize()
            
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            showAlert(message: "Failed to save profile")
        }
    }
    
    private func showAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            showAlert(message: "Failed to get image")
            return
        }
        
        // Update UI immediately
        profileImageView.image = image
        
        // Upload image
        uploadImage(image) { [weak self] imageURL in
            guard let self = self else { return }
            
            if let imageURL = imageURL {
                // Save the profile with the new image URL
                if let name = self.nameTextField.text, !name.isEmpty {
                    self.saveProfile(name: name, imageURL: imageURL)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
} 
