import UIKit

struct Article {
    let title: String
    let description: String
    let url: String
    let imageUrl: String?
    let source: String
}

class DailyReadingViewController: UIViewController {
    
    private var articles: [Article] = []
    private var articlesByInterest: [(interest: String, articles: [Article])] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ArticleCell.self, forCellReuseIdentifier: "ArticleCell")
        tv.separatorStyle = .none
        return tv
    }()
    
    private let refreshControl = UIRefreshControl()
    
    override func viewWillAppear(_ animated: Bool) {
     super.viewWillAppear(animated)
        // Show the tab bar when HomeScreenViewController appears
     tabBarController?.tabBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = true
        view.backgroundColor = .systemBackground
        title = "Daily Reading"
        setupUI()
        loadArticles()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(refreshArticles), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadArticles() {
        guard let data = UserDefaults.standard.data(forKey: "userInterests"),
              let interests = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            showNoInterestsAlert()
            return
        }
        
        // Join interests with OR for the API query
        let query = interests.joined(separator: " OR ")
        fetchArticles(for: query)
    }
    
    @objc private func refreshArticles() {
        loadArticles()
    }
    
    private func fetchArticles(for query: String) {
        guard let data = UserDefaults.standard.data(forKey: "userInterests"),
              let interests = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return
        }
        
        let apiKey = "34937cb764f749b4bfc8f3f5164d5a2f"
        let dispatchGroup = DispatchGroup()
        
        // Temporary container for results.
        var results = [(interest: String, articles: [Article])]()
        
        // A serial queue to avoid race conditions.
        let syncQueue = DispatchQueue(label: "com.AIProductivity.usedArticleURLs")
        var usedArticleURLs = Set<String>()
        
        // Fetch articles for each interest.
        for interest in interests {
            dispatchGroup.enter()
            
            // Restrict to English; adjust pageSize as needed.
            let urlString = "https://newsapi.org/v2/everything?q=\(interest)&language=en&sortBy=publishedAt&pageSize=5&apiKey=\(apiKey)"
            guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: encodedString) else {
                dispatchGroup.leave()
                continue
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { dispatchGroup.leave() }
                guard let data = data else { return }
                
                do {
                    // Parse JSON.
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let articles = json?["articles"] as? [[String: Any]] {
                        let parsedArticles = articles.compactMap { articleData -> Article? in
                            guard let title = articleData["title"] as? String,
                                  let description = articleData["description"] as? String,
                                  let url = articleData["url"] as? String,
                                  let source = (articleData["source"] as? [String: Any])?["name"] as? String else {
                                return nil
                            }
                            
                            let imageUrl = articleData["urlToImage"] as? String
                            let article = Article(title: title,
                                                  description: description,
                                                  url: url,
                                                  imageUrl: imageUrl,
                                                  source: source)
                            
                            // Ensure there are no duplicate URLs.
                            var isDuplicate = false
                            syncQueue.sync {
                                if usedArticleURLs.contains(article.url) {
                                    isDuplicate = true
                                } else {
                                    usedArticleURLs.insert(article.url)
                                }
                            }
                            return isDuplicate ? nil : article
                        }
                        
                        if !parsedArticles.isEmpty {
                            syncQueue.sync {
                                results.append((interest: interest, articles: parsedArticles))
                            }
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }.resume()
        }
        
        // Reload the table view only after all fetches are complete.
        dispatchGroup.notify(queue: .main) { [weak self] in
            self?.articlesByInterest = results
            self?.tableView.reloadData()
            self?.refreshControl.endRefreshing()
        }
    }
    
    private func showNoInterestsAlert() {
        let alert = UIAlertController(title: "No Interests Selected",
                                    message: "Please select your interests in the Edit Profile section to see personalized articles.",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension DailyReadingViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return articlesByInterest.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articlesByInterest[section].articles.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return articlesByInterest[section].interest
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = articlesByInterest[section].interest
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
        let article = articlesByInterest[indexPath.section].articles[indexPath.row]
        cell.configure(with: article)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let article = articlesByInterest[indexPath.section].articles[indexPath.row]
        let articleDetailVC = ArticleDetailViewController(article: article)
        navigationController?.pushViewController(articleDetailVC, animated: true)
    }
}

class ArticleCell: UITableViewCell {
    private let articleImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray6
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(articleImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(sourceLabel)
        
        NSLayoutConstraint.activate([
            articleImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            articleImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            articleImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            articleImageView.widthAnchor.constraint(equalToConstant: 100),
            
            titleLabel.leadingAnchor.constraint(equalTo: articleImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: articleImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            sourceLabel.leadingAnchor.constraint(equalTo: articleImageView.trailingAnchor, constant: 12),
            sourceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with article: Article) {
        titleLabel.text = article.title
        descriptionLabel.text = article.description
        sourceLabel.text = article.source
        
        if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.articleImageView.image = image
                    }
                }
            }.resume()
        }
    }
}