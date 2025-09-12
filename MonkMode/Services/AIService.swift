//
//  AIService.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

final class AIService {
    static let shared = AIService()
    private init() {}

    func askFlashcard(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://router.huggingface.co/v1/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(TokenStore.huggingFace ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "openai/gpt-oss-120b:together",
            "messages": [["role": "user", "content": prompt]],
            "stream": false
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil))); return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let text = message["content"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
