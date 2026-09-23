//
//  CoreDataBookmarksStoreTests.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsFeed

final class CoreDataBookmarksStoreTests: XCTestCase {

    func test_retrieve_deliversEmptySetOnEmptyStore() {
        let sut = makeSUT()

        expect(sut, toRetrieve: [])
    }

    func test_retrieve_hasNoSideEffectsOnEmptyStore() {
        let sut = makeSUT()

        expect(sut, toRetrieve: [])
        expect(sut, toRetrieve: [])
    }

    func test_insert_deliversInsertedIDsOnRetrieval() {
        let sut = makeSUT()
        let id1 = UUID()
        let id2 = UUID()

        insertBookmark(for: id1, to: sut)
        insertBookmark(for: id2, to: sut)

        expect(sut, toRetrieve: [id1, id2])
    }

    func test_insert_isIdempotentForSameEventID() {
        let sut = makeSUT()
        let id = UUID()

        insertBookmark(for: id, to: sut)
        let error = insertBookmark(for: id, to: sut)

        XCTAssertNil(error)
        expect(sut, toRetrieve: [id])
    }

    func test_delete_removesOnlyTheGivenBookmark() {
        let sut = makeSUT()
        let id1 = UUID()
        let id2 = UUID()
        insertBookmark(for: id1, to: sut)
        insertBookmark(for: id2, to: sut)

        deleteBookmark(for: id1, from: sut)

        expect(sut, toRetrieve: [id2])
    }

    func test_delete_deliversNoErrorOnMissingBookmark() {
        let sut = makeSUT()

        let error = deleteBookmark(for: UUID(), from: sut)

        XCTAssertNil(error)
    }

    func test_bookmarks_surviveEventsCacheDeletion() {
        let store = makeStore()
        let id = UUID()
        insertBookmark(for: id, to: store)

        let exp = expectation(description: "Wait for cache deletion")
        store.deleteCachedEvents { _ in exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        expect(store, toRetrieve: [id])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> BookmarksStore {
        return makeStore(file: file, line: line)
    }

    private func makeStore(file: StaticString = #filePath, line: UInt = #line) -> CoreDataEventsStore {
        let sut = try! CoreDataEventsStore(storeURL: URL(fileURLWithPath: "/dev/null"))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    private func insertBookmark(for id: UUID, to sut: BookmarksStore) -> Error? {
        let exp = expectation(description: "Wait for bookmark insertion")
        var receivedError: Error?
        sut.insertBookmark(for: id) { result in
            if case let .failure(error) = result { receivedError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }

    @discardableResult
    private func deleteBookmark(for id: UUID, from sut: BookmarksStore) -> Error? {
        let exp = expectation(description: "Wait for bookmark deletion")
        var receivedError: Error?
        sut.deleteBookmark(for: id) { result in
            if case let .failure(error) = result { receivedError = error }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedError
    }

    private func expect(_ sut: BookmarksStore, toRetrieve expectedIDs: Set<UUID>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for bookmarks retrieval")
        sut.retrieveBookmarkedEventIDs { result in
            switch result {
            case let .success(ids):
                XCTAssertEqual(ids, expectedIDs, file: file, line: line)
            case let .failure(error):
                XCTFail("Expected \(expectedIDs), got \(error) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
