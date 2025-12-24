import Foundation
#if canImport(UIKit)
import UIKit
#endif

internal final class NetworkManager {

    private let session: URLSession
    private let reachability: ReachabilityMonitor

    init(session: URLSession = .shared) {
        self.session = session
        self.reachability = ReachabilityMonitor()
    }

    func uploadBatch(
        events: [LocationEvent],
        endpoint: String,
        authToken: String?,
        compressed: Bool = true,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: endpoint) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let payload = BatchUploadPayload(events: events, metadata: createMetadata())
            var data = try encoder.encode(payload)

            if compressed && data.count > 1024 {
                if let compressed = try? (data as NSData).compressed(using: .lzfse) as Data {
                    data = compressed
                    request.setValue("lzfse", forHTTPHeaderField: "Content-Encoding")
                }
            }

            request.httpBody = data

        } catch {
            completion(.failure(error))
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.httpError(statusCode: httpResponse.statusCode)))
                return
            }

            completion(.success(()))
        }

        task.resume()
    }

    func isNetworkAvailable() -> Bool {
        return reachability.isReachable
    }

    func isWiFiConnected() -> Bool {
        return reachability.isWiFi
    }

    func startMonitoring(onChange: @escaping (Bool) -> Void) {
        reachability.startMonitoring(onChange: onChange)
    }

    func stopMonitoring() {
        reachability.stopMonitoring()
    }

    private func createMetadata() -> [String: String] {
        var metadata: [String: String] = [
            "platform": "ios",
            "sdk_version": "1.0.0"
        ]

        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            metadata["app_version"] = appVersion
        }

        #if canImport(UIKit)
        metadata["device_model"] = UIDevice.current.model
        metadata["os_version"] = UIDevice.current.systemVersion
        #endif

        return metadata
    }
}

private struct BatchUploadPayload: Codable {
    let events: [LocationEvent]
    let metadata: [String: String]
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noData
}
