// ChatGPTService.swift (Unified with legacy features and healing comparison)
import Foundation
import UIKit

struct GPTMessage: Codable {
    let role: String
    let content: String
}

struct GPTRequest: Codable {
    let model: String
    let messages: [GPTMessage]
}

struct GPTChoice: Codable {
    let message: GPTMessage
}

struct GPTResponse: Codable {
    let choices: [GPTChoice]
}

class ChatGPTService {
    static let shared = ChatGPTService()

    private let apiKey = Secrets.openAIKey
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    private let universalInstruction = """
    You are a helpful assistant. Provide concise, structured responses using labeled sections. Include disclaimers when necessary.
    """

    // MARK: - Bite Diagnosis (with User Profile)
    func sendImagePromptWithProfile(
        base64Image: String,
        symptomText: String?,
        user: User,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
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

        let prompt = """
        You are a helpful assistant trained in dermatology and entomology. Analyze the provided image and user data to determine the likely insect or cause of a bite or skin reaction.

        Respond in the following structured format:

        Insect or Cause: ...
        Pattern Description: ...
        Severity: ...
        Recommended Care: ...
        Recommended Products:
        - Product Name – Short Description (include URL if applicable)
        - ...
        Possible Risks: ...
        When to Seek Medical Attention: ...
        Danger Level (1-10): ...
        Disclaimer: This is not a medical diagnosis and should not be treated as such.

        User Notes: \(finalSymptomText)
        """

        sendImagePrompt(base64Image: base64Image, userText: profile + "\n" + prompt, completion: completion)
    }

    // MARK: - Plant Identification
    func sendPlantPrompt(base64Image: String, userNotes: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        You are a knowledgeable botanist. Based on the provided image and notes, identify the most likely plant and provide relevant safety or usage information.

        Respond in the following format:
        Species: ...
        Appearance: ...
        Toxicity: ...
        Common Uses (if any): ...
        Region or Habitat: ...
        Notes: ...
        Disclaimer: This is not a scientific identification or medical recommendation.

        User Notes: \(userNotes)
        """

        sendImagePrompt(base64Image: base64Image, userText: prompt, completion: completion)
    }

    // MARK: - Animal Identification
    func sendAnimalPrompt(base64Image: String, userNotes: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        You are a trained zoologist. Based on the provided image and context, identify the most likely animal and assess potential risk to humans.

        Respond in the following format:
        Species: ...
        Behavior Observed: ...
        Typical Habitat: ...
        Risk to Humans: ...
        Conservation Status: ...
        Disclaimer: This is an AI-generated identification and may not be fully accurate.

        User Notes: \(userNotes)
        """

        sendImagePrompt(base64Image: base64Image, userText: prompt, completion: completion)
    }

    // MARK: - Healing Comparison
    func sendHealingComparison(day1URL: String, dayXURL: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        Compare these two wound photos:
        - First photo (Day 1): \(day1URL)
        - Second photo: \(dayXURL)

        Based on the appearance of the wound, describe whether the condition is:
        • Healing
        • Unchanged
        • Worsening

        Provide a 1–2 sentence explanation. Do not give medical advice.
        """

        sendTextPrompt(prompt: prompt, completion: completion)
    }

    // MARK: - Generic Image Handler
    private func sendImagePrompt(base64Image: String, userText: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let contentPayload: [[String: Any]] = [
            ["type": "text", "text": userText],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
        ]

        let messages: [[String: Any]] = [
            ["role": "system", "content": universalInstruction],
            ["role": "user", "content": contentPayload]
        ]

        let payload: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": messages,
            "max_tokens": 1000
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let content = (((json?["choices"] as? [[String: Any]])?.first)?["message"] as? [String: Any])?["content"] as? String
                completion(.success(content ?? "No response."))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Simple Text Prompt
    func sendTextPrompt(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
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
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let content = (((json?["choices"] as? [[String: Any]])?.first)?["message"] as? [String: Any])?["content"] as? String
                completion(.success(content ?? "No response."))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
