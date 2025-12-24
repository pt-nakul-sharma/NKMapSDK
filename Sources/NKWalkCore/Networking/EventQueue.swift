import Foundation

internal final class EventQueue {

    private let storage: LocalStorageManager
    private let queue = DispatchQueue(label: "com.nkwalk.eventqueue", attributes: .concurrent)
    private var inMemoryQueue: [LocationEvent] = []
    private let maxInMemorySize = 1000

    init(storage: LocalStorageManager) {
        self.storage = storage
        loadPersistedEvents()
    }

    func enqueue(_ event: LocationEvent) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self.inMemoryQueue.append(event)

            if self.inMemoryQueue.count >= self.maxInMemorySize {
                self.persistToDisk()
            }
        }
    }

    func dequeueBatch(size: Int) -> [LocationEvent] {
        var batch: [LocationEvent] = []

        queue.sync {
            let count = min(size, inMemoryQueue.count)
            batch = Array(inMemoryQueue.prefix(count))
        }

        return batch
    }

    func removeBatch(_ batch: [LocationEvent]) {
        let batchIDs = Set(batch.map { $0.location.id })

        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            self.inMemoryQueue.removeAll { event in
                batchIDs.contains(event.location.id)
            }

            self.persistToDisk()
        }
    }

    func updateRetryCount(for event: LocationEvent) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if let index = self.inMemoryQueue.firstIndex(where: { $0.location.id == event.location.id }) {
                var updated = event
                updated.retryCount += 1
                updated.lastRetryAt = Date()
                self.inMemoryQueue[index] = updated
            }
        }
    }

    func count() -> Int {
        var count = 0
        queue.sync {
            count = inMemoryQueue.count
        }
        return count
    }

    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.inMemoryQueue.removeAll()
            self.storage.clearEventQueue()
        }
    }

    func persistToDisk() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.storage.saveEventQueue(self.inMemoryQueue)
        }
    }

    private func loadPersistedEvents() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if let persisted = self.storage.loadEventQueue() {
                self.inMemoryQueue = persisted
            }
        }
    }
}
