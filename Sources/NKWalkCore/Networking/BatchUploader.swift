import Foundation

internal final class BatchUploader {

    private let networkManager: NetworkManager
    private let eventQueue: EventQueue
    private let config: Configuration

    private var syncTimer: Timer?
    private var isSyncing = false
    private let syncQueue = DispatchQueue(label: "com.nkwalk.batchuploader")

    init(networkManager: NetworkManager, eventQueue: EventQueue, config: Configuration) {
        self.networkManager = networkManager
        self.eventQueue = eventQueue
        self.config = config
    }

    func startPeriodicSync() {
        stopPeriodicSync()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.syncTimer = Timer.scheduledTimer(
                withTimeInterval: self.config.syncSettings.syncIntervalSeconds,
                repeats: true
            ) { [weak self] _ in
                self?.syncNow()
            }
        }

        networkManager.startMonitoring { [weak self] isConnected in
            if isConnected {
                self?.syncNow()
            }
        }
    }

    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        networkManager.stopMonitoring()
    }

    func syncNow() {
        syncQueue.async { [weak self] in
            self?.performSync()
        }
    }

    private func performSync() {
        guard !isSyncing else { return }
        guard networkManager.isNetworkAvailable() else { return }

        if config.syncSettings.wifiOnlySync && !networkManager.isWiFiConnected() {
            return
        }

        let queueCount = eventQueue.count()
        guard queueCount > 0 else { return }

        isSyncing = true

        let batch = eventQueue.dequeueBatch(size: config.syncSettings.batchSize)
        guard !batch.isEmpty else {
            isSyncing = false
            return
        }

        uploadBatch(batch, attempt: 0)
    }

    private func uploadBatch(_ batch: [LocationEvent], attempt: Int) {
        let endpoint = config.endpoints.eventsBatch

        networkManager.uploadBatch(
            events: batch,
            endpoint: endpoint,
            authToken: nil,
            compressed: config.syncSettings.compressionEnabled
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.eventQueue.removeBatch(batch)
                self.isSyncing = false

                if self.eventQueue.count() > 0 {
                    self.syncNow()
                }

            case .failure(let error):
                self.handleUploadFailure(batch: batch, attempt: attempt, error: error)
            }
        }
    }

    private func handleUploadFailure(batch: [LocationEvent], attempt: Int, error: Error) {
        let maxRetries = config.syncSettings.maxRetryAttempts

        guard attempt < maxRetries else {
            batch.forEach { event in
                eventQueue.updateRetryCount(for: event)
            }
            isSyncing = false
            return
        }

        let backoffMultiplier = config.syncSettings.retryBackoffMultiplier
        let delay = pow(backoffMultiplier, Double(attempt))

        syncQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.uploadBatch(batch, attempt: attempt + 1)
        }
    }

    deinit {
        stopPeriodicSync()
    }
}
