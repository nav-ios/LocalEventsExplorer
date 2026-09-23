//
//  LoadEventsFromCacheUseCaseTests.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsFeed

final class LoadEventsFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrieval(with: retrievalError)
        })
    }

    func test_load_deliversEmptyCacheErrorOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .failure(LocalEventsLoader.LoadError.emptyCache), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }

    func test_load_deliversCachedEventsOnNonExpiredCache() {
        let events = uniqueEvents()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(events.models), when: {
            store.completeRetrieval(with: events.local, timestamp: nonExpiredTimestamp)
        })
    }

    func test_load_deliversExpiredCacheErrorOnCacheExpiration() {
        let events = uniqueEvents()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .failure(LocalEventsLoader.LoadError.expiredCache), when: {
            store.completeRetrieval(with: events.local, timestamp: expirationTimestamp)
        })
    }

    func test_load_deliversExpiredCacheErrorOnExpiredCache() {
        let events = uniqueEvents()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .failure(LocalEventsLoader.LoadError.expiredCache), when: {
            store.completeRetrieval(with: events.local, timestamp: expiredTimestamp)
        })
    }

    func test_load_deliversCachedEventsOnExpiredCacheWhenPolicyNeverExpires() {
        let events = uniqueEvents()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusCacheMaxAge().adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate }, policy: .neverExpires)

        expect(sut, toCompleteWith: .success(events.models), when: {
            store.completeRetrieval(with: events.local, timestamp: expiredTimestamp)
        })
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = EventsStoreSpy()
        var sut: LocalEventsLoader? = LocalEventsLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalEventsLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }

        sut = nil
        store.completeRetrievalWithEmptyCache()

        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, policy: EventsCachePolicy = .thirtyMinutes, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalEventsLoader, store: EventsStoreSpy) {
        let store = EventsStoreSpy()
        let sut = LocalEventsLoader(store: store, currentDate: currentDate, policy: policy)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func expect(_ sut: LocalEventsLoader, toCompleteWith expectedResult: LocalEventsLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedEvents), .success(expectedEvents)):
                XCTAssertEqual(receivedEvents, expectedEvents, file: file, line: line)

            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
}
