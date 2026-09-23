//
//  LocalEventsLoaderTests.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsFeed

final class LocalEventsLoaderTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()

        sut.save(uniqueEvents().models) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        sut.save(uniqueEvents().models) { _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents])
    }

    func test_save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let events = uniqueEvents()
        let (sut, store) = makeSUT(currentDate: { timestamp })

        sut.save(events.models) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCachedEvents, .insert(events.local, timestamp)])
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalEventsLoader, store: EventsStoreSpy) {
        let store = EventsStoreSpy()
        let sut = LocalEventsLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func uniqueEvent() -> Event {
        return Event(
            id: UUID(),
            title: "any title",
            location: EventLocation(name: "any place", latitude: 43.65, longitude: -79.38),
            time: Date(),
            imageURL: anyURL()
        )
    }

    private func uniqueEvents() -> (models: [Event], local: [LocalEvent]) {
        let models = [uniqueEvent(), uniqueEvent()]
        let local = models.map {
            LocalEvent(
                id: $0.id,
                title: $0.title,
                locationName: $0.location.name,
                latitude: $0.location.latitude,
                longitude: $0.location.longitude,
                time: $0.time,
                imageURL: $0.imageURL
            )
        }
        return (models, local)
    }

    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
