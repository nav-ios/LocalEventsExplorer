//
//  EventsAPITests.swift
//  EventsMockAPITests
//
//  Created by Navdeep Rana on 22/09/26.
//

import XCTest
import EventsMockAPI

final class EventsAPITests: XCTestCase {

    override func tearDown() {
        super.tearDown()

        MockAPIURLProtocol.unregister()
    }

    func test_getEvents_delivers200WithEventsListContainingRequiredFields() throws {
        let result = resultFor(EventsAPI.eventsURL)

        XCTAssertEqual(result.response?.statusCode, 200)
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: XCTUnwrap(result.data)) as? [String: Any])
        let events = try XCTUnwrap(root["events"] as? [[String: Any]])
        XCTAssertEqual(events.count, 12)

        for event in events {
            XCTAssertNotNil(UUID(uuidString: event["id"] as? String ?? ""), "id should be a UUID")
            XCTAssertNotNil(event["title"] as? String)
            XCTAssertNotNil((event["location"] as? [String: Any])?["name"] as? String)
            XCTAssertNotNil((event["location"] as? [String: Any])?["latitude"] as? Double)
            XCTAssertNotNil((event["location"] as? [String: Any])?["longitude"] as? Double)
            XCTAssertNotNil(ISO8601DateFormatter().date(from: event["time"] as? String ?? ""), "time should be ISO 8601")
            XCTAssertNotNil(URL(string: event["imageURL"] as? String ?? ""))
        }
    }

    func test_getEventByID_deliversMatchingEvent() throws {
        let list = resultFor(EventsAPI.eventsURL)
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: XCTUnwrap(list.data)) as? [String: Any])
        let first = try XCTUnwrap((root["events"] as? [[String: Any]])?.first)
        let id = try XCTUnwrap(first["id"] as? String)

        let result = resultFor(EventsAPI.eventsURL.appendingPathComponent(id))

        XCTAssertEqual(result.response?.statusCode, 200)
        let event = try XCTUnwrap(try JSONSerialization.jsonObject(with: XCTUnwrap(result.data)) as? [String: Any])
        XCTAssertEqual(event["id"] as? String, id)
        XCTAssertEqual(event["title"] as? String, first["title"] as? String)
    }

    func test_getEventByID_delivers404ForUnknownID() {
        let result = resultFor(EventsAPI.eventsURL.appendingPathComponent(UUID().uuidString))

        XCTAssertEqual(result.response?.statusCode, 404)
    }

    // MARK: - Helpers

    private func resultFor(_ url: URL) -> (data: Data?, response: HTTPURLResponse?, error: Error?) {
        let session = URLSession(configuration: .mockAPI(EventsAPI.makeServer(latency: 0)))
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
