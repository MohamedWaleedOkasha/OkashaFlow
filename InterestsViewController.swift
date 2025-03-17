import UIKit

class InterestsViewController: UIViewController {
    
    var isInitialSetup = false
    
    private let interests = [
        "Technology", "Science", "Business", "Health",
        "Sports", "Entertainment", "Politics", "Education",
        "Art", "Travel", "Food", "Music",
        "Fashion", "Environment", "Literature", "Gaming"
    ]
    
    private var selectedInterests: Set<String> = []
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(InterestCell.self, forCellWithReuseIdentifier: "InterestCell")
        return cv
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = isInitialSetup ? "Choose Your Interests" : "Your Interests"
        setupUI()
        loadInterests()
        
        saveButton.setTitle(isInitialSetup ? "Continue" : "Save Changes", for: .normal)
    }
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(saveButton)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 200),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        saveButton.addTarget(self, action: #selector(saveInterestsTapped), for: .touchUpInside)
    }
    
    private func loadInterests() {
        if let data = UserDefaults.standard.data(forKey: "userInterests"),
           let interests = try? JSONDecoder().decode(Set<String>.self, from: data) {
            selectedInterests = interests
            collectionView.reloadData()
        }
    }
    
    @objc private func saveInterestsTapped() {
        guard !selectedInterests.isEmpty else {
            showAlert(message: "Please select at least one interest")
            return
        }
        
        if let encoded = try? JSONEncoder().encode(selectedInterests) {
            UserDefaults.standard.set(encoded, forKey: "userInterests")
        }
        
        if isInitialSetup {
            // Navigate to Home Screen after initial setup
            let homeVC = HomeScreenViewController()
            let navigationController = UINavigationController(rootViewController: homeVC)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true)
        } else {
            // Go back to previous screen
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension InterestsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return interests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InterestCell", for: indexPath) as! InterestCell
        let interest = interests[indexPath.item]
        cell.configure(with: interest, isSelected: selectedInterests.contains(interest))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let interest = interests[indexPath.item]
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 60) / 2 // 2 columns with padding
        return CGSize(width: width, height: 50)
    }
}

class InterestCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12
        contentView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with interest: String, isSelected: Bool) {
        titleLabel.text = interest
        contentView.backgroundColor = isSelected ? .systemBlue : .systemGray6
        titleLabel.textColor = isSelected ? .white : .label
    }
} 