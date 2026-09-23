//
//  LocalImageDataLoaderTests.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsFeed

final class LocalImageDataLoaderTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertTrue(store.receivedMessages.isEmpty)
    }

    func test_loadImageDataFromURL_requestsStoredDataForURL() {
        let (sut, store) = makeSUT()
        let url = anyURL()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(store.receivedMessages, [.retrieve(dataFor: url)])
    }

    func test_loadImageDataFromURL_failsOnStoreError() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: failed(), when: {
            store.completeRetrieval(with: anyNSError())
        })
    }

    func test_loadImageDataFromURL_deliversNotFoundErrorOnNotFound() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: notFound(), when: {
            store.completeRetrieval(with: .none)
        })
    }

    func test_loadImageDataFromURL_deliversStoredDataOnFoundData() {
        let (sut, store) = makeSUT()
        let foundData = anyData()

        expect(sut, toCompleteWith: .success(foundData), when: {
            store.completeRetrieval(with: foundData)
        })
    }

    func test_loadImageDataFromURL_doesNotDeliverResultAfterCancellingTask() {
        let (sut, store) = makeSUT()

        var received = [ImageDataLoader.Result]()
        let task = sut.loadImageData(from: anyURL()) { received.append($0) }
        task.cancel()

        store.completeRetrieval(with: anyData())
        store.completeRetrieval(with: .none)
        store.completeRetrieval(with: anyNSError())

        XCTAssertTrue(received.isEmpty)
    }

    func test_saveImageDataForURL_requestsImageDataInsertionForURL() {
        let (sut, store) = makeSUT()
        let url = anyURL()
        let data = anyData()

        sut.save(data, for: url) { _ in }

        XCTAssertEqual(store.receivedMessages, [.insert(data: data, for: url)])
    }

    func test_saveImageDataFromURL_failsOnStoreInsertionError() {
        let (sut, store) = makeSUT()

        expectSave(sut, toCompleteWith: .failure(LocalImageDataLoader.SaveError.failed), when: {
            store.completeInsertion(with: anyNSError())
        })
    }

    func test_saveImageDataFromURL_succeedsOnSuccessfulStoreInsertion() {
        let (sut, store) = makeSUT()

        expectSave(sut, toCompleteWith: .success(()), when: {
            store.completeInsertionSuccessfully()
        })
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy()
        let sut = LocalImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func failed() -> ImageDataLoader.Result {
        return .failure(LocalImageDataLoader.LoadError.failed)
    }

    private func notFound() -> ImageDataLoader.Result {
        return .failure(LocalImageDataLoader.LoadError.notFound)
    }

    private func expect(_ sut: LocalImageDataLoader, toCompleteWith expectedResult: ImageDataLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)

            case let (.failure(receivedError as LocalImageDataLoader.LoadError), .failure(expectedError as LocalImageDataLoader.LoadError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func expectSave(_ sut: LocalImageDataLoader, toCompleteWith expectedResult: ImageDataCache.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")

        sut.save(anyData(), for: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success, .success):
                break

            case let (.failure(receivedError as LocalImageDataLoader.SaveError), .failure(expectedError as LocalImageDataLoader.SaveError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }

    private class ImageDataStoreSpy: ImageDataStore {
        enum Message: Equatable {
            case insert(data: Data, for: URL)
            case retrieve(dataFor: URL)
        }

        private(set) var receivedMessages = [Message]()
        private var retrievalCompletions = [(ImageDataStore.RetrievalResult) -> Void]()
        private var insertionCompletions = [(ImageDataStore.InsertionResult) -> Void]()

        func retrieve(dataForURL url: URL, completion: @escaping (ImageDataStore.RetrievalResult) -> Void) {
            receivedMessages.append(.retrieve(dataFor: url))
            retrievalCompletions.append(completion)
        }

        func insert(_ data: Data, for url: URL, completion: @escaping (ImageDataStore.InsertionResult) -> Void) {
            receivedMessages.append(.insert(data: data, for: url))
            insertionCompletions.append(completion)
        }

        func completeRetrieval(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }

        func completeRetrieval(with data: Data?, at index: Int = 0) {
            retrievalCompletions[index](.success(data))
        }

        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](.failure(error))
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](.success(()))
        }
    }
}
