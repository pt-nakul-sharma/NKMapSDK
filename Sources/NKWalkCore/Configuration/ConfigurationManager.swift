import Foundation

internal final class ConfigurationManager {

    private let storage: LocalStorageManager
    private let session: URLSession

    init(storage: LocalStorageManager, session: URLSession = .shared) {
        self.storage = storage
        self.session = session
    }

    func fetchConfiguration(apiKey: String, completion: @escaping (Result<Configuration, NKWalkError>) -> Void) {
        if let cached = storage.loadConfiguration(), !isConfigurationExpired(cached) {
            completion(.success(cached))
            return
        }

        let endpoint = "https://api.nkwalk.com/api/v1/config"
        guard let url = URL(string: endpoint) else {
            completion(.failure(.configurationFailed(reason: "Invalid endpoint URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                if let cached = self.storage.loadConfiguration() {
                    completion(.success(cached))
                } else {
                    completion(.failure(.networkError(underlying: error)))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.configurationFailed(reason: "Invalid response")))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let cached = self.storage.loadConfiguration() {
                    completion(.success(cached))
                } else {
                    completion(.failure(.configurationFailed(reason: "HTTP \(httpResponse.statusCode)")))
                }
                return
            }

            guard let data = data else {
                completion(.failure(.configurationFailed(reason: "No data received")))
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let config = try decoder.decode(Configuration.self, from: data)

                self.storage.saveConfiguration(config)

                completion(.success(config))
            } catch {
                if let cached = self.storage.loadConfiguration() {
                    completion(.success(cached))
                } else {
                    completion(.failure(.configurationFailed(reason: "Failed to parse: \(error.localizedDescription)")))
                }
            }
        }

        task.resume()
    }

    private func isConfigurationExpired(_ config: Configuration) -> Bool {
        guard let savedDate = storage.getConfigurationSavedDate() else {
            return true
        }

        let expiryInterval: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(savedDate) > expiryInterval
    }
}
