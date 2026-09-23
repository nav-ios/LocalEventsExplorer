//
//  MockAPIURLProtocolTests.swift
//  EventsMockAPITests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsMockAPI

final class MockAPIURLProtocolTests: XCTestCase {

    override func tearDown() {
        super.tearDown()

        MockAPIURLProtocol.unregister()
    }

    func test_urlSession_receivesRegisteredRouteResponse() {
        let server = makeServer()
        let body = Data(#"{"events":[]}"#.utf8)
        server.register("GET", "/events") { _ in .json(body) }

        let result = resultFor(URL(string: "https://api.local-events.test/events")!, on: server)

        XCTAssertEqual(result.data, body)
        XCTAssertEqual(result.response?.statusCode, 200)
        XCTAssertEqual(result.response?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNil(result.error)
    }

    func test_urlSession_receives404ForUnknownRoute() {
        let server = makeServer()

        let result = resultFor(URL(string: "https://api.local-events.test/unknown")!, on: server)

        XCTAssertEqual(result.response?.statusCode, 404)
    }

    func test_urlSession_receivesSimulatedFailureOnceAndThenRecovers() {
        let server = makeServer()
        server.register("GET", "/events") { _ in .json(Data()) }
        let url = URL(string: "https://api.local-events.test/events")!
        server.simulatedFailure = URLError(.notConnectedToInternet)

        let failed = resultFor(url, on: server)
        let recovered = resultFor(url, on: server)

        XCTAssertEqual((failed.error as? URLError)?.code, .notConnectedToInternet)
        XCTAssertNil(recovered.error)
        XCTAssertEqual(recovered.response?.statusCode, 200)
    }

    func test_urlSession_deliversResponseAfterConfiguredLatency() {
        let server = makeServer(latency: 0.2)
        server.register("GET", "/events") { _ in .json(Data()) }

        let start = Date()
        _ = resultFor(URL(string: "https://api.local-events.test/events")!, on: server)

        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.2)
    }

    // MARK: - Helpers

    private func makeServer(latency: TimeInterval = 0) -> MockAPIServer {
        return MockAPIServer(baseURL: URL(string: "https://api.local-events.test")!, latency: latency)
    }

    private func resultFor(_ url: URL, on server: MockAPIServer, file: StaticString = #filePath, line: UInt = #line) -> (data: Data?, response: HTTPURLResponse?, error: Error?) {
        let session = URLSession(configuration: .mockAPI(server))
        let exp = expectation(description: "Wait for request")

        var received: (Data?, HTTPURLResponse?, Error?) = (nil, nil, nil)
        session.dataTask(with: url) { data, response, error in
            received = (data, response as? HTTPURLResponse, error)
            exp.fulfill()
        }.resume()

        wait(for: [exp], timeout: 2.0)
        return received
    }
}
