//
//  InMemoryImageDataStoreTests.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsFeed

final class InMemoryImageDataStoreTests: XCTestCase {

    func test_retrieveImageData_deliversNotFoundWhenEmpty() {
        let sut = makeSUT()

        expect(sut, toCompleteRetrievalWith: notFound(), for: anyURL())
    }

    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() {
        let sut = makeSUT()
        let url = URL(string: "https://a-url.com")!
        let nonMatchingURL = URL(string: "https://another-url.com")!

        insert(anyData(), for: url, into: sut)

        expect(sut, toCompleteRetrievalWith: notFound(), for: nonMatchingURL)
    }

    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() {
        let sut = makeSUT()
        let storedData = anyData()
        let url = anyURL()

        insert(storedData, for: url, into: sut)

        expect(sut, toCompleteRetrievalWith: found(storedData), for: url)
    }

    func test_retrieveImageData_deliversLastInsertedValue() {
        let sut = makeSUT()
        let firstStoredData = Data("first".utf8)
        let lastStoredData = Data("last".utf8)
        let url = anyURL()

        insert(firstStoredData, for: url, into: sut)
        insert(lastStoredData, for: url, into: sut)

        expect(sut, toCompleteRetrievalWith: found(lastStoredData), for: url)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> InMemoryImageDataStore {
        let sut = InMemoryImageDataStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func notFound() -> ImageDataStore.RetrievalResult {
        return .success(.none)
    }

    private func found(_ data: Data) -> ImageDataStore.RetrievalResult {
        return .success(data)
    }

    private func expect(_ sut: InMemoryImageDataStore, toCompleteRetrievalWith expectedResult: ImageDataStore.RetrievalResult, for url: URL, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for retrieval")
        sut.retrieve(dataForURL: url) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedData), .success(expectedData)):
                XCTAssertEqual(receivedData, expectedData, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func insert(_ data: Data, for url: URL, into sut: InMemoryImageDataStore, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for insertion")
        sut.insert(data, for: url) { result in
            if case let .failure(error) = result {
                XCTFail("Failed to insert \(data) with error \(error)", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
