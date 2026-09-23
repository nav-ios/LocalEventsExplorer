//
//  MockAPIServerTests.swift
//  EventsMockAPITests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsMockAPI

final class MockAPIServerTests: XCTestCase {

    func test_response_deliversNotFoundWhenNoRouteIsRegistered() {
        let sut = makeSUT()

        let response = sut.response(for: request("GET", "/events"))

        XCTAssertEqual(response, .notFound)
    }

    func test_response_deliversRegisteredRouteResponseOnMatchingMethodAndPath() {
        let sut = makeSUT()
        let expected = MockAPIResponse.json(Data("[]".utf8))
        sut.register("GET", "/events") { _ in expected }

        XCTAssertEqual(sut.response(for: request("GET", "/events")), expected)
    }

    func test_response_deliversNotFoundOnMatchingPathWithDifferentMethod() {
        let sut = makeSUT()
        sut.register("GET", "/events") { _ in .json(Data()) }

        XCTAssertEqual(sut.response(for: request("POST", "/events")), .notFound)
    }

    func test_response_extractsPathParameters() {
        let sut = makeSUT()
        var receivedID: String?
        sut.register("GET", "/events/:id") { request in
            receivedID = request.pathParameters["id"]
            return .json(Data())
        }

        _ = sut.response(for: request("GET", "/events/42"))

        XCTAssertEqual(receivedID, "42")
    }

    func test_response_deliversNotFoundWhenPathDepthDoesNotMatch() {
        let sut = makeSUT()
        sut.register("GET", "/events/:id") { _ in .json(Data()) }

        XCTAssertEqual(sut.response(for: request("GET", "/events")), .notFound)
        XCTAssertEqual(sut.response(for: request("GET", "/events/42/photos")), .notFound)
    }

    func test_response_passesQueryItemsToHandler() {
        let sut = makeSUT()
        var receivedItems = [URLQueryItem]()
        sut.register("GET", "/events") { request in
            receivedItems = request.queryItems
            return .json(Data())
        }

        _ = sut.response(for: request("GET", "/events?lat=43.6&lon=-79.3"))

        XCTAssertEqual(receivedItems, [URLQueryItem(name: "lat", value: "43.6"), URLQueryItem(name: "lon", value: "-79.3")])
    }

    func test_handles_isTrueOnlyForRequestsToTheBaseURL() {
        let sut = makeSUT(baseURL: URL(string: "https://api.local-events.test")!)

        XCTAssertTrue(sut.handles(URLRequest(url: URL(string: "https://api.local-events.test/events")!)))
        XCTAssertFalse(sut.handles(URLRequest(url: URL(string: "https://images.example.com/photo.jpg")!)))
        XCTAssertFalse(sut.handles(URLRequest(url: URL(string: "http://api.local-events.test/events")!)))
    }

    // MARK: - Helpers

    private func makeSUT(baseURL: URL = URL(string: "https://api.local-events.test")!) -> MockAPIServer {
        return MockAPIServer(baseURL: baseURL)
    }

    private func request(_ method: String, _ path: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.local-events.test" + path)!)
        request.httpMethod = method
        return request
    }
}
