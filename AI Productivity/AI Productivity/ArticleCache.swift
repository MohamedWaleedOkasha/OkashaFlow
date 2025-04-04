//class ArticleCache {
//    static let shared = ArticleCache()
//    private var cache: [String: (timestamp: Date, articles: [Article])] = [:]
//    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
//    
//    func getCachedArticles(for interest: String) -> [Article]? {
//        guard let cached = cache[interest],
//              Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration else {
//            return nil
//        }
//        return cached.articles
//    }
//    
//    func cacheArticles(_ articles: [Article], for interest: String) {
//        cache[interest] = (Date(), articles)
//    }
//} 
