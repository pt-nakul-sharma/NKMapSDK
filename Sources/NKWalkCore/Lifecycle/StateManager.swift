import Foundation
#if canImport(UIKit)
import UIKit
#endif

internal final class StateManager {

    var onAppDidEnterBackground: (() -> Void)?
    var onAppWillEnterForeground: (() -> Void)?
    var onAppWillTerminate: (() -> Void)?

    var batchUploader: BatchUploader?
    var eventQueue: EventQueue?

    private var observers: [NSObjectProtocol] = []

    func startObserving() {
        stopObserving()

        #if canImport(UIKit)
        let backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBackgroundTransition()
        }
        observers.append(backgroundObserver)

        let foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleForegroundTransition()
        }
        observers.append(foregroundObserver)

        let terminateObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleTermination()
        }
        observers.append(terminateObserver)
        #endif
    }

    func stopObserving() {
        observers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }

    func setBatchUploader(_ uploader: BatchUploader) {
        self.batchUploader = uploader
    }

    func setEventQueue(_ queue: EventQueue) {
        self.eventQueue = queue
    }

    private func handleBackgroundTransition() {
        eventQueue?.persistToDisk()

        batchUploader?.syncNow()

        onAppDidEnterBackground?()
    }

    private func handleForegroundTransition() {
        onAppWillEnterForeground?()
    }

    private func handleTermination() {
        eventQueue?.persistToDisk()

        onAppWillTerminate?()
    }

    deinit {
        stopObserving()
    }
}
