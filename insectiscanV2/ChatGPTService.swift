// ChatGPTService.swift (Advanced Version with Professional Improvements)
import Foundation
import UIKit
import CoreLocation
import CommonCrypto

// MARK: - Request/Response Data Models
struct GPTMessage: Codable {
    let role: String
    let content: [GPTContent]
}

struct GPTContent: Codable {
    let type: String
    let text: String?
    let image_url: ImageURL?

    struct ImageURL: Codable {
        let url: String
    }
}

struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
    let max_tokens: Int
}

struct GPTChoice: Codable {
    let message: GPTMessageWrapper
}

struct GPTMessageWrapper: Codable {
    let role: String
    let content: String
}

struct GPTResponse: Codable {
    let choices: [GPTChoice]
}

// MARK: - Analysis Data Models
struct BiteAnalysis {
    let insectOrCause: String
    let patternDescription: String
    let severity: String
    let recommendedCare: String
    let recommendedProducts: [String]
    let possibleRisks: String
    let medicalAttentionSigns: String
    let dangerLevel: Int
    let confidence: String
    let isActuallyBugBite: Bool
    let rawResponse: String
    
    static func parse(from response: String) -> Result<BiteAnalysis, ChatGPTServiceError> {
        // Check if it's not a bug bite
        if response.starts(with: "Not a Bug Bite:") {
            return .failure(.notABugBite(response.replacingOccurrences(of: "Not a Bug Bite:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        
        // Parse the structured response
        var insectOrCause = ""
        var patternDescription = ""
        var severity = ""
        var recommendedCare = ""
        var recommendedProducts: [String] = []
        var possibleRisks = ""
        var medicalAttentionSigns = ""
        var dangerLevel = 0
        var confidence = "Medium"
        
        let lines = response.components(separatedBy: "\n")
        var currentSection: String?
        var inProductsSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            if trimmedLine.contains(":") {
                let components = trimmedLine.components(separatedBy: ":")
                if components.count >= 2 {
                    let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    switch key {
                    case "Insect or Cause":
                        insectOrCause = value
                    case "Pattern Description":
                        patternDescription = value
                    case "Severity":
                        severity = value
                    case "Recommended Care":
                        recommendedCare = value
                    case "Possible Risks":
                        possibleRisks = value
                    case "When to Seek Medical Attention":
                        medicalAttentionSigns = value
                    case "Danger Level (1-10)":
                        if let levelStr = value.components(separatedBy: CharacterSet.decimalDigits.inverted).first,
                           let level = Int(levelStr) {
                            dangerLevel = max(1, min(10, level)) // Ensure it's 1-10
                        }
                    case "Confidence":
                        confidence = value
                    case "Recommended Products":
                        inProductsSection = true
                        currentSection = key
                    default:
                        break
                    }
                }
            } else if inProductsSection && trimmedLine.starts(with: "-") {
                let product = trimmedLine.dropFirst().trimmingCharacters(in: .whitespaces)
                if !product.isEmpty {
                    recommendedProducts.append(product)
                }
            }
        }
        
        // Validation
        if insectOrCause.isEmpty {
            return .failure(.parsingError("Could not find insect or cause in response"))
        }
        
        if dangerLevel == 0 {
            // Set a default danger level if parsing failed
            dangerLevel = 5
        }
        
        return .success(BiteAnalysis(
            insectOrCause: insectOrCause,
            patternDescription: patternDescription,
            severity: severity,
            recommendedCare: recommendedCare,
            recommendedProducts: recommendedProducts,
            possibleRisks: possibleRisks,
            medicalAttentionSigns: medicalAttentionSigns,
            dangerLevel: dangerLevel,
            confidence: confidence,
            isActuallyBugBite: true,
            rawResponse: response
        ))
    }
}

// MARK: - Error Handling
enum ChatGPTServiceError: Error, LocalizedError {
    case networkError(Error)
    case apiLimitExceeded
    case invalidResponse(Int)
    case noData
    case imageTooLarge
    case notABugBite(String)
    case parsingError(String)
    case timeout
    case serverError(Int)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to the internet. Please check your connection and try again."
        case .apiLimitExceeded:
            return "We've reached our limit for AI analysis. Please try again in a few minutes."
        case .invalidResponse(let code):
            return "We received an invalid response from our AI service (Code: \(code)). Please try again."
        case .noData:
            return "No data was received from the analysis service. Please try again."
        case .imageTooLarge:
            return "Your image is too large. Please try a smaller image or reduce the quality."
        case .notABugBite(let explanation):
            if !explanation.isEmpty {
                return "This doesn't appear to be a bug bite: \(explanation)"
            }
            return "Our AI couldn't detect a bug bite in this image. Please try another photo."
        case .parsingError:
            return "There was an error processing the response. Please try again."
        case .timeout:
            return "The request timed out. Please try again when you have a stronger connection."
        case .serverError(let code):
            return "The AI service is experiencing issues (Error \(code)). Please try again later."
        case .unauthorized:
            return "Authentication error. Please restart the app or contact support."
        }
    }
}

// MARK: - Analysis Context
struct AnalysisContext {
    let location: CLLocation?
    let activity: String?
    let timeOfDay: String?
    let indoorOutdoor: String?
    let previousExposure: Bool?
    let seasonalData: SeasonalData
    
    struct SeasonalData {
        let season: String
        let temperature: Double?
        let humidity: Double?
        let rainfall: Double?
        
        static func current() -> SeasonalData {
            // In a real implementation, you would fetch this data
            // from a weather API based on the user's location
            let month = Calendar.current.component(.month, from: Date())
            let season: String
            
            switch month {
            case 12, 1, 2: season = "Winter"
            case 3, 4, 5: season = "Spring"
            case 6, 7, 8: season = "Summer"
            case 9, 10, 11: season = "Fall"
            default: season = "Unknown"
            }
            
            return SeasonalData(
                season: season,
                temperature: nil,
                humidity: nil,
                rainfall: nil
            )
        }
    }
    
    static func current(location: CLLocation? = nil, activity: String? = nil) -> AnalysisContext {
        return AnalysisContext(
            location: location,
            activity: activity,
            timeOfDay: getCurrentTimeOfDay(),
            indoorOutdoor: nil,
            previousExposure: nil,
            seasonalData: SeasonalData.current()
        )
    }
    
    private static func getCurrentTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...11: return "Morning"
        case 12...17: return "Afternoon"
        case 18...21: return "Evening"
        default: return "Night"
        }
    }
    
    func asPromptString() -> String {
        var result = "Environmental Context:\n"
        
        if let location = location {
            let geocoder = CLGeocoder()
            
            // Synchronous geocoding (for demo purposes)
            // In production, you would use the async version with callbacks
            let semaphore = DispatchSemaphore(value: 0)
            var locationString = "Unknown"
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? "Unknown City"
                    let state = placemark.administrativeArea ?? "Unknown State"
                    let country = placemark.country ?? "Unknown Country"
                    locationString = "\(city), \(state), \(country)"
                }
                semaphore.signal()
            }
            
            // Wait for geocoding (with timeout)
            _ = semaphore.wait(timeout: .now() + 2.0)
            
            result += "- Location: \(locationString)\n"
        }
        
        result += "- Season: \(seasonalData.season)\n"
        
        if let activity = activity {
            result += "- Activity: \(activity)\n"
        }
        
        if let timeOfDay = timeOfDay {
            result += "- Time of Day: \(timeOfDay)\n"
        }
        
        if let indoorOutdoor = indoorOutdoor {
            result += "- Setting: \(indoorOutdoor)\n"
        }
        
        return result
    }
}

// MARK: - Progress Tracking
struct AnalysisProgress {
    enum Stage {
        case preparing
        case uploading(progress: Double)
        case analyzing
        case processingResponse
        case complete
        case error(Error)
    }
    
    let stage: Stage
    let message: String
    
    static func getMessage(for stage: Stage) -> String {
        switch stage {
        case .preparing:
            return "Preparing image for analysis..."
        case .uploading(let progress):
            return "Uploading image... \(Int(progress * 100))%"
        case .analyzing:
            return "AI analyzing your image..."
        case .processingResponse:
            return "Processing results..."
        case .complete:
            return "Analysis complete!"
        case .error(let error):
            if let serviceError = error as? ChatGPTServiceError {
                return serviceError.errorDescription ?? "An error occurred"
            }
            return "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Image Caching System
class ImageHashCache {
    static let shared = ImageHashCache()
    private var cache: [String: CacheEntry] = [:]
    private let cacheLock = NSLock()
    
    struct CacheEntry {
        let response: String
        let timestamp: Date
        
        var isValid: Bool {
            // Cache entries expire after 24 hours
            return Date().timeIntervalSince(timestamp) < 86400
        }
    }
    
    func getCachedResponse(for imageHash: String) -> String? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard let entry = cache[imageHash], entry.isValid else {
            // Remove expired entries
            if let entry = cache[imageHash], !entry.isValid {
                cache.removeValue(forKey: imageHash)
            }
            return nil
        }
        
        return entry.response
    }
    
    func cacheResponse(_ response: String, for imageHash: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let entry = CacheEntry(response: response, timestamp: Date())
        cache[imageHash] = entry
    }
    
    func generateHash(for imageData: Data) -> String {
        // Simple MD5 hash for demo purposes
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = imageData.withUnsafeBytes { bufferPtr in
            CC_MD5(bufferPtr.baseAddress, CC_LONG(imageData.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache.removeAll()
    }
}

// MARK: - Analytics Manager
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    enum EventType: String {
        case scanStarted = "scan_started"
        case scanCompleted = "scan_completed"
        case errorOccurred = "error_occurred"
        case resultViewed = "result_viewed"
        case productClicked = "product_clicked"
        case emergencyCareAdvised = "emergency_care_advised"
    }
    
    func logEvent(_ eventType: EventType, metadata: [String: Any] = [:]) {
        // In a real app, you would send this to your analytics service
        print("📊 Analytics event: \(eventType.rawValue) at \(Date())")
        
        // For privacy reasons, we're not logging user-identifiable information
        var safeMetadata: [String: Any] = [:]
        for (key, value) in metadata {
            if key != "userId" && key != "locationString" {
                safeMetadata[key] = value
            }
        }
        
        // Example Firebase Analytics integration
        // FirebaseAnalytics.logEvent(name: eventType.rawValue, parameters: safeMetadata)
    }
}

// MARK: - Local Fallback Classification
class LocalBiteClassifier {
    // This is a simplified approximation for when the API is unavailable
    // In a real implementation, you would use a lightweight on-device model
    
    static func classifyImage(_ image: UIImage) -> BiteAnalysis {
        // Analyze average redness in the image
        let redness = calculateRedness(image)
        
        // Basic bug bite classification based on redness
        let dangerLevel: Int
        let insectOrCause: String
        let severity: String
        
        if redness > 0.7 {
            dangerLevel = 7
            insectOrCause = "Possible severe reaction or fire ant"
            severity = "Significant"
        } else if redness > 0.4 {
            dangerLevel = 4
            insectOrCause = "Mosquito or common bug bite"
            severity = "Moderate"
        } else {
            dangerLevel = 2
            insectOrCause = "Minor irritation or mild insect bite"
            severity = "Mild"
        }
        
        return BiteAnalysis(
            insectOrCause: insectOrCause,
            patternDescription: "Redness and possible swelling",
            severity: severity,
            recommendedCare: "Clean with soap and water. Apply ice to reduce swelling.",
            recommendedProducts: ["Hydrocortisone cream", "Antihistamine"],
            possibleRisks: "Infection if scratched excessively",
            medicalAttentionSigns: "Spreading redness, fever, or difficulty breathing",
            dangerLevel: dangerLevel,
            confidence: "Low (offline mode)",
            isActuallyBugBite: true,
            rawResponse: "Generated by offline mode"
        )
    }
    
    private static func calculateRedness(_ image: UIImage) -> Double {
        // In a real app, you would implement an algorithm to detect red areas
        // This is a placeholder
        return Double.random(in: 0.1...0.8)
    }
}

// MARK: - Main ChatGPT Service
class ChatGPTService {
    // MARK: - Properties
    static let shared = ChatGPTService()
    private let apiKey = Secrets.openAIKey
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let session: URLSession
    private let universalInstruction = """
    You are a helpful assistant. Provide concise, structured responses using labeled sections. Include disclaimers when necessary.
    """
    
    // MARK: - Progress Tracking
    typealias ProgressCallback = (AnalysisProgress) -> Void
    
    // MARK: - Initialization
    private init() {
        // Configure URLSession with longer timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 120.0
        session = URLSession(configuration: config)
    }
    
    // MARK: - Bite Diagnosis with User Profile
    func sendImagePromptWithProfile(
        base64Image: String,
        symptomText: String?,
        user: User,
        context: AnalysisContext? = nil,
        progress: ProgressCallback? = nil,
        completion: @escaping (Result<BiteAnalysis, Error>) -> Void
    ) {
        // Log analytics event
        AnalyticsManager.shared.logEvent(.scanStarted, metadata: [
            "has_symptoms": !(symptomText?.isEmpty ?? true),
            "has_context": context != nil
        ])
        
        progress?(.init(stage: .preparing, message: AnalysisProgress.getMessage(for: .preparing)))
        
        // Check for cached response if available
        if let imageData = Data(base64Encoded: base64Image),
           !imageData.isEmpty {
            
            let imageHash = ImageHashCache.shared.generateHash(for: imageData)
            if let cachedResponse = ImageHashCache.shared.getCachedResponse(for: imageHash) {
                print("🔄 Using cached response for image")
                
                progress?(.init(stage: .processingResponse, message: AnalysisProgress.getMessage(for: .processingResponse)))
                
                // Parse the cached response
                let analysisResult = BiteAnalysis.parse(from: cachedResponse)
                switch analysisResult {
                case .success(let analysis):
                    progress?(.init(stage: .complete, message: AnalysisProgress.getMessage(for: .complete)))
                    completion(.success(analysis))
                case .failure(let error):
                    progress?(.init(stage: .error(error), message: AnalysisProgress.getMessage(for: .error(error))))
                    completion(.failure(error))
                }
                
                return
            }
        }
        
        // Build user profile
        let profile = """
        User Profile:
        - Age: \(user.age ?? 0)
        - Gender: \(user.gender ?? "Unknown")
        - Skin Color: \(user.skinColor ?? "Unknown")
        - Allergies: \(user.allergies?.joined(separator: ", ") ?? "None")
        - Medical Conditions: \(user.medicalConditions?.joined(separator: ", ") ?? "None")
        """

        let finalSymptomText = (symptomText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            ? "Red or irritated skin after outdoor exposure. Unknown cause. Slight swelling and itchiness."
            : symptomText!
            
        // Add environmental context if available
        let environmentalContext = context?.asPromptString() ?? ""

        let enhancedPrompt = """
        You are an expert in dermatology and entomology specializing in insect bite identification. Analyze the image and user data to determine the likely cause of a skin reaction.
        
        \(profile)
        
        \(environmentalContext)
        
        User Notes: \(finalSymptomText)
        
        **FIRST:** Determine if the image actually shows a bug bite, sting, or related skin reaction. If you're confident it is NOT a bug bite or sting (e.g., it's a random object, unrelated skin condition, or non-medical image), respond with ONLY:
        
        Not a Bug Bite: [Brief explanation of what the image actually shows]
        
        HOWEVER, if it appears to be a possible bug bite, sting, or related skin reaction, respond in this EXACT format:
        
        Insect or Cause: [Most likely insect or cause]
        
        Pattern Description: [Brief description of bite appearance]
        
        Severity: [Brief assessment of severity]
        
        Recommended Care: [1-3 concise treatment recommendations]
        
        Recommended Products:
        - [Product] – [Brief description]
        - [Product] – [Brief description]
        
        Possible Risks: [Brief mention of potential complications]
        
        When to Seek Medical Attention: [1-2 clear indicators for medical care]
        
        Danger Level (1-10): [Number between 1-10]
        
        Confidence: [High/Medium/Low] - [Brief reason for confidence level]
        
        Disclaimer: This is not a medical diagnosis and should not replace professional medical advice.
        """
        
        print("📤 Submitting scan to ChatGPT...")
        
        // Try local analysis if offline
        let reachability = NetworkReachability.shared
        if !reachability.isConnected {
            print("⚠️ Offline mode - using local classification")
            progress?(.init(stage: .analyzing, message: "Offline mode - using basic analysis"))
            
            // Decode base64 image
            guard let imageData = Data(base64Encoded: base64Image),
                  let image = UIImage(data: imageData) else {
                let error = ChatGPTServiceError.noData
                progress?(.init(stage: .error(error), message: AnalysisProgress.getMessage(for: .error(error))))
                completion(.failure(error))
                return
            }
            
            // Use local classifier
            let analysis = LocalBiteClassifier.classifyImage(image)
            progress?(.init(stage: .complete, message: AnalysisProgress.getMessage(for: .complete)))
            completion(.success(analysis))
            return
        }
        
        // Send with retry logic
        sendImagePromptWithRetry(
            base64Image: base64Image,
            userText: enhancedPrompt,
            maxRetries: 3,
            progress: progress,
            completion: { result in
                switch result {
                case .success(let response):
                    print("✅ Received response: \(response)")
                    
                    // Cache the response
                    if let imageData = Data(base64Encoded: base64Image) {
                        let imageHash = ImageHashCache.shared.generateHash(for: imageData)
                        ImageHashCache.shared.cacheResponse(response, for: imageHash)
                    }
                    
                    // Parse the response
                    progress?(.init(stage: .processingResponse, message: AnalysisProgress.getMessage(for: .processingResponse)))
                    
                    let analysisResult = BiteAnalysis.parse(from: response)
                    switch analysisResult {
                    case .success(let analysis):
                        // Log analytics for successful scan
                        AnalyticsManager.shared.logEvent(.scanCompleted, metadata: [
                            "danger_level": analysis.dangerLevel,
                            "insect_type": analysis.insectOrCause,
                            "confidence": analysis.confidence
                        ])
                        
                        progress?(.init(stage: .complete, message: AnalysisProgress.getMessage(for: .complete)))
                        completion(.success(analysis))
                        
                        // Check if emergency care is advised
                        if analysis.dangerLevel >= 8 {
                            AnalyticsManager.shared.logEvent(.emergencyCareAdvised)
                        }
                        
                    case .failure(let error):
                        // Log analytics for parsing error
                        AnalyticsManager.shared.logEvent(.errorOccurred, metadata: [
                            "error_type": "parsing_error",
                            "message": error.localizedDescription
                        ])
                        
                        progress?(.init(stage: .error(error), message: AnalysisProgress.getMessage(for: .error(error))))
                        completion(.failure(error))
                    }
                    
                case .failure(let error):
                    // Log analytics for error
                    AnalyticsManager.shared.logEvent(.errorOccurred, metadata: [
                        "error_type": String(describing: type(of: error)),
                        "message": error.localizedDescription
                    ])
                    
                    progress?(.init(stage: .error(error), message: AnalysisProgress.getMessage(for: .error(error))))
                    completion(.failure(error))
                }
            }
        )
    }

    // MARK: - Healing Comparison with Improved Error Handling
    func sendHealingComparison(
        day1URL: String,
        dayXURL: String,
        daysSince: Int,
        progress: ProgressCallback? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        progress?(.init(stage: .preparing, message: AnalysisProgress.getMessage(for: .preparing)))
        
        let streamlinedComparisonPrompt = """
        Compare these two wound photos:
        - First photo (Day 1): \(day1URL)
        - Second photo (Day \(daysSince)): \(dayXURL)

        Based on the appearance, provide a concise assessment:
        
        Healing Status: [Healing/Unchanged/Worsening]
        
        Visual Changes:
        - Size: [Increased/Decreased/Same]
        - Color: [Better/Worse/Same]
        - Swelling: [Better/Worse/Same]
        
        Treatment Recommendation: [Brief 1-2 sentence advice]
        
        When to Seek Medical Care: [Specific warning signs]
        
        Provide a brief explanation (2-3 sentences max). Do not give extensive medical advice.
        """
        
        progress?(.init(stage: .analyzing, message: AnalysisProgress.getMessage(for: .analyzing)))
        
        sendTextPromptWithRetry(
            prompt: streamlinedComparisonPrompt,
            maxRetries: 2,
            progress: progress,
            completion: completion
        )
    }

    // MARK: - Plant Analysis with Enhanced Context
    func sendPlantPrompt(
        base64Image: String,
        userNotes: String,
        location: CLLocation? = nil,
        progress: ProgressCallback? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Get location string if available
        var locationString = ""
        if let location = location {
            let geocoder = CLGeocoder()
            let semaphore = DispatchSemaphore(value: 0)
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    if let country = placemark.country {
                        locationString = country
                    }
                    if let state = placemark.administrativeArea {
                        locationString = "\(state), \(locationString)"
                    }
                }
                semaphore.signal()
            }
            
            // Wait with timeout
            _ = semaphore.wait(timeout: .now() + 2.0)
        }
        
        let locationContext = locationString.isEmpty ? "" : "Location context: \(locationString)"
        
        progress?(.init(stage: .preparing, message: AnalysisProgress.getMessage(for: .preparing)))
        
        let streamlinedPlantPrompt = """
        Identify the plant in this image and provide key safety information. User notes: "\(userNotes)"
        \(locationContext)
        
        Respond in this format:
        
        Species: [Most likely plant name]
        
        Appearance: [Brief description]
        
        Toxicity: [Non-toxic/Mildly toxic/Moderately toxic/Highly toxic]
        
        Common Uses (if any): [Brief description if applicable]
        
        Region or Habitat: [Brief description]
        
        Notes: [Any important additional information]
        
        Disclaimer: This is not a scientific identification or medical recommendation.
        """
        
        sendImagePromptWithRetry(
            base64Image: base64Image,
            userText: streamlinedPlantPrompt,
            maxRetries: 2,
            progress: progress,
            completion: completion
        )
    }

    // MARK: - Animal Analysis with Improved Context
    func sendAnimalPrompt(
        base64Image: String,
        userNotes: String,
        location: CLLocation? = nil,
        progress: ProgressCallback? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Get location string if available
        var locationString = ""
        if let location = location {
            let geocoder = CLGeocoder()
            let semaphore = DispatchSemaphore(value: 0)
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    if let country = placemark.country {
                        locationString = country
                    }
                    if let state = placemark.administrativeArea {
                        locationString = "\(state), \(locationString)"
                    }
                }
                semaphore.signal()
            }
            
            // Wait with timeout
            _ = semaphore.wait(timeout: .now() + 2.0)
        }
        
        let locationContext = locationString.isEmpty ? "" : "Location context: \(locationString)"
        
        progress?(.init(stage: .preparing, message: AnalysisProgress.getMessage(for: .preparing)))
        
        let streamlinedAnimalPrompt = """
        Identify the animal in this image and assess potential risks. User notes: "\(userNotes)"
        \(locationContext)
        
        Respond in this format:
        
        Species: [Most likely animal identification]
        
        Behavior Observed: [Brief description based on image]
        
        Typical Habitat: [Where this animal is commonly found]
        
        Risk to Humans: [None/Low/Moderate/High] - [Brief explanation]
        
        Conservation Status: [Common/Threatened/Endangered/Protected]
        
        Disclaimer: This is an AI-generated identification and may not be fully accurate.
        """
        
        sendImagePromptWithRetry(
            base64Image: base64Image,
            userText: streamlinedAnimalPrompt,
            maxRetries: 2,
            progress: progress,
            completion: completion
        )
    }

    // MARK: - Image Handler with Retry Logic
    private func sendImagePromptWithRetry(
        base64Image: String,
        userText: String,
        maxRetries: Int = 3,
        progress: ProgressCallback? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var retryCount = 0
        
        func attemptRequest() {
            progress?(.init(stage: .uploading(progress: 0.1), message: AnalysisProgress.getMessage(for: .uploading(progress: 0.1))))
            
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 60.0

            let content: [GPTContent] = [
                GPTContent(type: "text", text: universalInstruction, image_url: nil),
                GPTContent(type: "text", text: userText, image_url: nil),
                GPTContent(type: "image_url", text: nil, image_url: .init(url: "data:image/jpeg;base64,\(base64Image)"))
            ]

            let messages = [
                GPTMessage(role: "user", content: content)
            ]

            let payload = GPTRequest(model: "gpt-4o", messages: messages, max_tokens: 1000)

            do {
                request.httpBody = try JSONEncoder().encode(payload)
            } catch {
                print("❌ Encoding error: \(error.localizedDescription)")
                completion(.failure(ChatGPTServiceError.parsingError("Failed to encode request: \(error.localizedDescription)")))
                return
            }

            print("📡 Sending image prompt to OpenAI (attempt \(retryCount + 1) of \(maxRetries))...")
            
            progress?(.init(stage: .uploading(progress: 0.4), message: AnalysisProgress.getMessage(for: .uploading(progress: 0.4))))

            let task = session.dataTask(with: request) { data, response, error in
                // Handle network errors
                if let error = error as NSError? {
                    if error.domain == NSURLErrorDomain &&
                      (error.code == NSURLErrorTimedOut ||
                       error.code == NSURLErrorNotConnectedToInternet ||
                       error.code == NSURLErrorNetworkConnectionLost) {
                        if retryCount < maxRetries - 1 {
                            retryCount += 1
                            let delay = pow(2.0, Double(retryCount))
                            print("⚠️ Request failed. Retrying in \(delay) seconds...")
                            
                            // Show retry in progress callback
                            progress?(.init(
                                stage: .error(ChatGPTServiceError.timeout),
                                message: "Connection issue. Retrying in \(Int(delay)) seconds..."
                            ))
                            
                            // Implement exponential backoff
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                attemptRequest()
                            }
                            return
                        }
                        
                        // Max retries reached
                        if error.code == NSURLErrorTimedOut {
                            completion(.failure(ChatGPTServiceError.timeout))
                        } else {
                            completion(.failure(ChatGPTServiceError.networkError(error)))
                        }
                        return
                    }
                    
                    // Other network errors
                    completion(.failure(ChatGPTServiceError.networkError(error)))
                    return
                }
                
                progress?(.init(stage: .uploading(progress: 0.9), message: AnalysisProgress.getMessage(for: .uploading(progress: 0.9))))
                
                // Handle HTTP errors
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Status code: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        // Success, continue processing
                        break
                    case 401:
                        completion(.failure(ChatGPTServiceError.unauthorized))
                        return
                    case 429:
                        completion(.failure(ChatGPTServiceError.apiLimitExceeded))
                        return
                    case 400...499:
                        completion(.failure(ChatGPTServiceError.invalidResponse(httpResponse.statusCode)))
                        return
                    case 500...599:
                        // Server errors may be transient, so retry
                        if retryCount < maxRetries - 1 {
                            retryCount += 1
                            let delay = pow(2.0, Double(retryCount))
                            print("⚠️ Server error. Retrying in \(delay) seconds...")
                            
                            progress?(.init(
                                stage: .error(ChatGPTServiceError.serverError(httpResponse.statusCode)),
                                message: "Server error. Retrying in \(Int(delay)) seconds..."
                            ))
                            
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                attemptRequest()
                            }
                            return
                        }
                        
                        completion(.failure(ChatGPTServiceError.serverError(httpResponse.statusCode)))
                        return
                    default:
                        completion(.failure(ChatGPTServiceError.invalidResponse(httpResponse.statusCode)))
                        return
                    }
                }

                guard let data = data, !data.isEmpty else {
                    print("❌ No data received from OpenAI")
                    completion(.failure(ChatGPTServiceError.noData))
                    return
                }
                
                progress?(.init(stage: .analyzing, message: AnalysisProgress.getMessage(for: .analyzing)))

                if let raw = String(data: data, encoding: .utf8) {
                    print("📦 Raw response from OpenAI:\n\(raw)")
                }

                do {
                    let json = try JSONDecoder().decode(GPTResponse.self, from: data)
                    let content = json.choices.first?.message.content
                    
                    if let responseContent = content {
                        completion(.success(responseContent))
                    } else {
                        completion(.failure(ChatGPTServiceError.noData))
                    }
                } catch {
                    print("❌ JSON decoding error: \(error.localizedDescription)")
                    completion(.failure(ChatGPTServiceError.parsingError("Failed to decode response: \(error.localizedDescription)")))
                }
            }
            
            task.resume()
        }
        
        attemptRequest()
    }

    // MARK: - Text Prompt with Retry Logic
    private func sendTextPromptWithRetry(
        prompt: String,
        maxRetries: Int = 3,
        progress: ProgressCallback? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var retryCount = 0
        
        func attemptRequest() {
            let messages = [
                ["role": "system", "content": universalInstruction],
                ["role": "user", "content": prompt]
            ]

            let payload: [String: Any] = [
                "model": "gpt-4",
                "messages": messages
            ]

            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30.0
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            } catch {
                completion(.failure(ChatGPTServiceError.parsingError("Failed to serialize request: \(error.localizedDescription)")))
                return
            }

            print("📡 Sending text prompt to OpenAI (attempt \(retryCount + 1) of \(maxRetries))...")

            let task = session.dataTask(with: request) { data, response, error in
                // Handle network errors
                if let error = error as NSError? {
                    if error.domain == NSURLErrorDomain &&
                      (error.code == NSURLErrorTimedOut ||
                       error.code == NSURLErrorNotConnectedToInternet ||
                       error.code == NSURLErrorNetworkConnectionLost) {
                        if retryCount < maxRetries - 1 {
                            retryCount += 1
                            let delay = pow(2.0, Double(retryCount))
                            print("⚠️ Request failed. Retrying in \(delay) seconds...")
                            
                            // Show retry in progress callback
                            progress?(.init(
                                stage: .error(ChatGPTServiceError.timeout),
                                message: "Connection issue. Retrying in \(Int(delay)) seconds..."
                            ))
                            
                            // Implement exponential backoff
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                attemptRequest()
                            }
                            return
                        }
                        
                        // Max retries reached
                        if error.code == NSURLErrorTimedOut {
                            completion(.failure(ChatGPTServiceError.timeout))
                        } else {
                            completion(.failure(ChatGPTServiceError.networkError(error)))
                        }
                        return
                    }
                    
                    // Other network errors
                    completion(.failure(ChatGPTServiceError.networkError(error)))
                    return
                }
                
                // Handle HTTP errors
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Status code: \(httpResponse.statusCode)")
                    
                    switch httpResponse.statusCode {
                    case 200...299:
                        // Success, continue processing
                        break
                    case 401:
                        completion(.failure(ChatGPTServiceError.unauthorized))
                        return
                    case 429:
                        completion(.failure(ChatGPTServiceError.apiLimitExceeded))
                        return
                    case 400...499:
                        completion(.failure(ChatGPTServiceError.invalidResponse(httpResponse.statusCode)))
                        return
                    case 500...599:
                        // Server errors may be transient, so retry
                        if retryCount < maxRetries - 1 {
                            retryCount += 1
                            let delay = pow(2.0, Double(retryCount))
                            print("⚠️ Server error. Retrying in \(delay) seconds...")
                            
                            progress?(.init(
                                stage: .error(ChatGPTServiceError.serverError(httpResponse.statusCode)),
                                message: "Server error. Retrying in \(Int(delay)) seconds..."
                            ))
                            
                            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                                attemptRequest()
                            }
                            return
                        }
                        
                        completion(.failure(ChatGPTServiceError.serverError(httpResponse.statusCode)))
                        return
                    default:
                        completion(.failure(ChatGPTServiceError.invalidResponse(httpResponse.statusCode)))
                        return
                    }
                }
                
                guard let data = data, !data.isEmpty else {
                    print("❌ No data received from OpenAI (text request)")
                    completion(.failure(ChatGPTServiceError.noData))
                    return
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                    print("📦 Raw text response:\n\(raw)")
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let content = (((json?["choices"] as? [[String: Any]])?.first)?["message"] as? [String: Any])?["content"] as? String {
                        completion(.success(content))
                    } else {
                        completion(.failure(ChatGPTServiceError.parsingError("Failed to extract content from response")))
                    }
                } catch {
                    print("❌ JSON decoding error (text request): \(error.localizedDescription)")
                    completion(.failure(ChatGPTServiceError.parsingError("Failed to decode response: \(error.localizedDescription)")))
                }
            }
            
            task.resume()
        }
        
        attemptRequest()
    }

    // MARK: - Utility Methods
    func clearCache() {
        ImageHashCache.shared.clearCache()
    }
}

// MARK: - Network Reachability Helper
class NetworkReachability {
    static let shared = NetworkReachability()
    
    var isConnected: Bool {
        // In a real app, you would use NWPathMonitor or Reachability
        // This is a simplified implementation
        return true
    }
}
