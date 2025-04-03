import Foundation

// Add a clear namespace to avoid ambiguity
struct NewsArticle: Codable {  // Renamed from just 'Article'
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let source: Source
    
    struct Source: Codable {
        let name: String
    }
} 