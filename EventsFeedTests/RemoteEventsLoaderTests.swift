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

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://any-url.com")!) -> (sut: RemoteEventsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteEventsLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        private(set) var requestedURLs = [URL]()

        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            requestedURLs.append(url)
        }
    }
}
