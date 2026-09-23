//
//  RemoteEventsLoaderTests.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsFeed

final class RemoteEventsLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromClientOnCreation() {
        let (_, client) = makeSUT()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_deliversConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: failure(.connectivity), when: {
            client.complete(with: anyNSError())
        })
    }

    func test_load_deliversInvalidDataErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500]

        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData), when: {
                client.complete(withStatusCode: code, data: anyData(), at: index)
            })
        }
    }

    func test_load_deliversInvalidDataErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }

    func test_load_deliversNoEventsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            let emptyListJSON = makeEventsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }

    func test_load_deliversEventsOn200HTTPResponseWithJSONList() {
        let (sut, client) = makeSUT()

        let event1 = makeEvent(
            id: UUID(),
            title: "Jazz Night",
            locationName: "Massey Hall",
            latitude: 43.6544,
            longitude: -79.3807,
            time: Date(timeIntervalSince1970: 1790000000),
            imageURL: URL(string: "https://a-url.com/jazz.jpg")!
        )

        let event2 = makeEvent(
            id: UUID(),
            title: "Food Festival",
            locationName: "Nathan Phillips Square",
            latitude: 43.6525,
            longitude: -79.3835,
            time: Date(timeIntervalSince1970: 1790100000),
            imageURL: URL(string: "https://a-url.com/food.jpg")!
        )

        expect(sut, toCompleteWith: .success([event1.model, event2.model]), when: {
            let json = makeEventsJSON([event1.json, event2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://any-url.com")!) -> (sut: RemoteEventsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteEventsLoader(url: url, client: client)
        return (sut, client)
    }

    private func failure(_ error: RemoteEventsLoader.Error) -> RemoteEventsLoader.Result {
        return .failure(error)
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

    private func anyData() -> Data {
        return Data("any data".utf8)
    }

    private func makeEvent(id: UUID, title: String, locationName: String, latitude: Double, longitude: Double, time: Date, imageURL: URL) -> (model: Event, json: [String: Any]) {
        let model = Event(
            id: id,
            title: title,
            location: EventLocation(name: locationName, latitude: latitude, longitude: longitude),
            time: time,
            imageURL: imageURL
        )

        let json: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "location": [
                "name": locationName,
                "latitude": latitude,
                "longitude": longitude
            ],
            "time": ISO8601DateFormatter().string(from: time),
            "imageURL": imageURL.absoluteString
        ]

        return (model, json)
    }

    private func makeEventsJSON(_ events: [[String: Any]]) -> Data {
        let json = ["events": events]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func expect(_ sut: RemoteEventsLoader, toCompleteWith expectedResult: RemoteEventsLoader.Result, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)

            case let (.failure(receivedError as RemoteEventsLoader.Error), .failure(expectedError as RemoteEventsLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()

        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()

        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            messages.append((url, completion))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.success((data, response)))
        }
    }
}
