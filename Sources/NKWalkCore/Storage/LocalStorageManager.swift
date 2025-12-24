import Foundation

internal final class LocalStorageManager {

    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let storageDirectory: URL

    private enum Keys {
        static let authToken = "com.nkwalk.authToken"
        static let tokenExpiry = "com.nkwalk.tokenExpiry"
        static let configuration = "com.nkwalk.configuration"
        static let configSavedDate = "com.nkwalk.configSavedDate"
    }

    init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.storageDirectory = appSupport.appendingPathComponent("NKWalk", isDirectory: true)

        createStorageDirectoryIfNeeded()
    }

    private func createStorageDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: storageDirectory.path) {
            try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }

    func saveAuthToken(_ token: String, expiry: Date) {
        userDefaults.set(token, forKey: Keys.authToken)
        userDefaults.set(expiry, forKey: Keys.tokenExpiry)
    }

    func loadAuthToken() -> (token: String, expiry: Date)? {
        guard let token = userDefaults.string(forKey: Keys.authToken),
              let expiry = userDefaults.object(forKey: Keys.tokenExpiry) as? Date else {
            return nil
        }
        return (token, expiry)
    }

    func clearAuthToken() {
        userDefaults.removeObject(forKey: Keys.authToken)
        userDefaults.removeObject(forKey: Keys.tokenExpiry)
    }

    func saveConfiguration(_ config: Configuration) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(config) {
            userDefaults.set(data, forKey: Keys.configuration)
            userDefaults.set(Date(), forKey: Keys.configSavedDate)
        }
    }

    func loadConfiguration() -> Configuration? {
        guard let data = userDefaults.data(forKey: Keys.configuration) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(Configuration.self, from: data)
    }

    func getConfigurationSavedDate() -> Date? {
        return userDefaults.object(forKey: Keys.configSavedDate) as? Date
    }

    func clearConfiguration() {
        userDefaults.removeObject(forKey: Keys.configuration)
        userDefaults.removeObject(forKey: Keys.configSavedDate)
    }

    func saveEventQueue(_ events: [LocationEvent]) {
        let url = storageDirectory.appendingPathComponent("event_queue.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(events) {
            try? data.write(to: url, options: .atomic)
        }
    }

    func loadEventQueue() -> [LocationEvent]? {
        let url = storageDirectory.appendingPathComponent("event_queue.json")

        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode([LocationEvent].self, from: data)
    }

    func clearEventQueue() {
        let url = storageDirectory.appendingPathComponent("event_queue.json")
        try? fileManager.removeItem(at: url)
    }

    func clearAll() {
        clearAuthToken()
        clearConfiguration()
        clearEventQueue()

        try? fileManager.removeItem(at: storageDirectory)
        createStorageDirectoryIfNeeded()
    }
}
