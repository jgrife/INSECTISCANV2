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

    private let universalInstruction = """
You are a helpful assistant. Provide concise, structured responses using labeled sections. Include disclaimers when necessary.
"""

    // MARK: - Bite Diagnosis
    func sendImagePromptWithProfile(
        base64Image: String,
        symptomText: String?,
        user: User,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let userContext = """
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
You are a helpful assistant trained in dermatology and entomology. Analyze the provided image and user information to determine the most likely insect or cause of a bite or skin reaction.

Even if image or symptom data is incomplete, provide your best educated guess. Clearly indicate uncertainty if applicable.

Respond in the following format:

Insect or Cause: ...
Pattern Description: ...
Severity: ...
Recommended Care: ...
Possible Risks: ...
When to Seek Medical Attention: ...
Danger Level (1-10): ...
Disclaimer: This is not a medical diagnosis and is not a substitute for professional evaluation.

User Notes: \(finalSymptomText)
"""

        sendImagePrompt(base64Image: base64Image, userText: userContext + "\n" + prompt, completion: completion)
    }

    // MARK: - Plant Identification
    func sendPlantPrompt(base64Image: String, userNotes: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
You are a knowledgeable botanist. Based on the provided image and notes, identify the most likely plant and provide relevant safety or usage information.

Respond in the following format (even if uncertain — give your best estimate):

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

Respond in the following format (respond even if unsure):

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

    // MARK: - Generic Image + Text Handler
    private func sendImagePrompt(base64Image: String, userText: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }

        var request = URLRequest(url: url)
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
            "model": "gpt-4o",
            "messages": messages
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }

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
                let responseText = (((json?["choices"] as? [[String: Any]])?.first)?["message"] as? [String: Any])?["content"] as? String
                completion(.success(responseText ?? "No response."))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
