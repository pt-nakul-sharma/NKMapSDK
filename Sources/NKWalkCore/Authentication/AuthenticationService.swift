import Foundation

internal final class AuthenticationService {

    private let storage: LocalStorageManager
    private let session: URLSession

    private var authToken: String?
    private var tokenExpiryDate: Date?

    init(storage: LocalStorageManager, session: URLSession = .shared) {
        self.storage = storage
        self.session = session

        loadCachedToken()
    }

    func authenticate(apiKey: String, completion: @escaping (Result<Void, NKWalkError>) -> Void) {
        if let token = authToken, let expiry = tokenExpiryDate, expiry > Date() {
            completion(.success(()))
            return
        }

        let endpoint = "https://api.nkwalk.com/api/v1/auth/validate"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.authenticationFailed(reason: "Invalid endpoint URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let body: [String: Any] = [
            "api_key": apiKey,
            "platform": "ios",
            "sdk_version": "1.0.0"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.authenticationFailed(reason: "Failed to serialize request")))
            return
        }

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(.networkError(underlying: error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.authenticationFailed(reason: "Invalid response")))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let reason = self.parseErrorReason(from: data) ?? "HTTP \(httpResponse.statusCode)"
                completion(.failure(.authenticationFailed(reason: reason)))
                return
            }

            guard let data = data else {
                completion(.failure(.authenticationFailed(reason: "No data received")))
                return
            }

            do {
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.authToken = authResponse.token
                self.tokenExpiryDate = Date().addingTimeInterval(authResponse.expiresIn)

                self.storage.saveAuthToken(authResponse.token, expiry: self.tokenExpiryDate!)

                completion(.success(()))
            } catch {
                completion(.failure(.authenticationFailed(reason: "Failed to parse response")))
            }
        }

        task.resume()
    }

    func getAuthToken() -> String? {
        guard let expiry = tokenExpiryDate, expiry > Date() else {
            return nil
        }
        return authToken
    }

    private func loadCachedToken() {
        if let cached = storage.loadAuthToken() {
            self.authToken = cached.token
            self.tokenExpiryDate = cached.expiry
        }
    }

    private func parseErrorReason(from data: Data?) -> String? {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String else {
            return nil
        }
        return message
    }
}

private struct AuthResponse: Codable {
    let token: String
    let expiresIn: TimeInterval

    enum CodingKeys: String, CodingKey {
        case token
        case expiresIn = "expires_in"
    }
}
