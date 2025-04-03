//import Foundation
//import SwiftSoup
//
//class WebScraper {
//    static func scrapeInterestingEngineering(for interest: String) async throws -> [Article] {
//        let urlString = "https://interestingengineering.com/search?q=\(interest)"
//        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
//            throw NSError(domain: "Invalid URL", code: -1)
//        }
//        
//        let (data, _) = try await URLSession.shared.data(from: url)
//        guard let html = String(data: data, encoding: .utf8) else {
//            throw NSError(domain: "Invalid HTML", code: -2)
//        }
//        
//        let doc = try SwiftSoup.parse(html)
//        let articleElements = try doc.select("article")
//        
//        var articles: [Article] = []
//        
//        for element in articleElements {
//            do {
//                let title = try element.select("h3").first()?.text() ?? ""
//                let description = try element.select("p").first()?.text() ?? ""
//                let url = try element.select("a").first()?.attr("href") ?? ""
//                let imageUrl = try element.select("img").first()?.attr("src")
//                let source = "Interesting Engineering"
//                
//                // Create full URL if it's a relative path
//                let fullUrl = url.starts(with: "http") ? url : "https://interestingengineering.com\(url)"
//                
//                let article = Article(
//                    title: title,
//                    description: description,
//                    url: fullUrl,
//                    imageUrl: imageUrl,
//                    source: source
//                )
//                
//                articles.append(article)
//            } catch {
//                print("Error parsing article: \(error)")
//                continue
//            }
//        }
//        
//        return articles
//    }
//} 
