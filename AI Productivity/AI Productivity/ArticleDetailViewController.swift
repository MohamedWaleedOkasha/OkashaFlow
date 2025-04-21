import UIKit
import WebKit

class ArticleDetailViewController: UIViewController {
    private let webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let article: Article
    
    init(article: Article) {
        self.article = article
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Show the tab bar when HomeScreenViewController appears
    tabBarController?.tabBar.isHidden = false
}
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadArticle()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = article.source
        
        view.addSubview(webView)
        view.addSubview(loadingIndicator)
        
        webView.navigationDelegate = self
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add a share button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareArticle)
        )
    }
    
    private func loadArticle() {
        loadingIndicator.startAnimating()
        if let url = URL(string: article.url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    @objc private func shareArticle() {
        let items = [article.title, article.url]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

extension ArticleDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        // Show error alert
        let alert = UIAlertController(title: "Error",
                                    message: "Failed to load the article. Please try again.",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
} 