import Foundation

struct APIManager {
    static var openAIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OpenAI_API_Key") as? String else {
            fatalError("🚨 OpenAI API Key is missing from Info.plist! Add it first.")
        }
        return key
    }
}
