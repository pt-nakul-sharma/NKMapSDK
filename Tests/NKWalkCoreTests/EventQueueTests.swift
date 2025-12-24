import XCTest
@testable import NKWalkCore

final class EventQueueTests: XCTestCase {

    var storage: MockStorageManager!
    var eventQueue: EventQueue!

    override func setUp() {
        super.setUp()
        storage = MockStorageManager()
        eventQueue = EventQueue(storage: storage)
    }

    override func tearDown() {
        eventQueue = nil
        storage = nil
        super.tearDown()
    }

    func testEnqueueEvent() {
        let location = LocationData(
            latitude: 37.7749,
            longitude: -122.4194,
            accuracy: 10.0,
            provider: "test"
        )
        let event = LocationEvent(location: location)

        eventQueue.enqueue(event)

        XCTAssertEqual(eventQueue.count(), 1)
    }

    func testDequeueBatch() {
        let events = createMockEvents(count: 10)
        events.forEach { eventQueue.enqueue($0) }

        let batch = eventQueue.dequeueBatch(size: 5)

        XCTAssertEqual(batch.count, 5)
        XCTAssertEqual(eventQueue.count(), 10)
    }

    func testRemoveBatch() {
        let events = createMockEvents(count: 10)
        events.forEach { eventQueue.enqueue($0) }

        let batch = eventQueue.dequeueBatch(size: 5)
        eventQueue.removeBatch(batch)

        XCTAssertEqual(eventQueue.count(), 5)
    }

    func testClear() {
        let events = createMockEvents(count: 10)
        events.forEach { eventQueue.enqueue($0) }

        eventQueue.clear()

        XCTAssertEqual(eventQueue.count(), 0)
    }

    func testPersistToDisk() {
        let events = createMockEvents(count: 5)
        events.forEach { eventQueue.enqueue($0) }

        eventQueue.persistToDisk()

        XCTAssertTrue(storage.saveEventQueueCalled)
    }

    private func createMockEvents(count: Int) -> [LocationEvent] {
        return (0..<count).map { i in
            let location = LocationData(
                latitude: 37.0 + Double(i) * 0.01,
                longitude: -122.0 + Double(i) * 0.01,
                accuracy: 10.0,
                provider: "test"
            )
            return LocationEvent(location: location)
        }
    }
}

class MockStorageManager: LocalStorageManager {

    var saveEventQueueCalled = false
    var savedEvents: [LocationEvent]?

    override func saveEventQueue(_ events: [LocationEvent]) {
        saveEventQueueCalled = true
        savedEvents = events
    }

    override func loadEventQueue() -> [LocationEvent]? {
        return savedEvents
    }
}
