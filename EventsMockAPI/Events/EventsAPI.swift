//
//  EventsAPI.swift
//  EventsMockAPI
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

/// The mock Events REST API.
///
/// - `GET /events`      → `{ "events": [ ... ] }`
/// - `GET /events/{id}` → a single event, or `404`
///
/// Data comes from the bundled `events.json` fixture, so the app behaves the same
/// on every machine without any backend running.
public enum EventsAPI {
    public static let baseURL = URL(string: "https://api.local-events.test")!

    public static var eventsURL: URL {
        return baseURL.appendingPathComponent("events")
    }

    public static func makeServer(latency: TimeInterval = 0.5) -> MockAPIServer {
        let server = MockAPIServer(baseURL: baseURL, latency: latency)

        server.register("GET", "/events") { _ in
            .json(fixtureData())
        }

        server.register("GET", "/events/:id") { request in
            guard let id = request.pathParameters["id"], let event = event(withID: id) else {
                return .notFound
            }
            return .json(event)
        }

        return server
    }

    static func fixtureData() -> Data {
        let bundle = Bundle(for: MockAPIServer.self)
        guard let url = bundle.url(forResource: "events", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            preconditionFailure("events.json fixture is missing from the EventsMockAPI bundle")
        }
        return data
    }

    private static func event(withID id: String) -> Data? {
        guard
            let root = try? JSONSerialization.jsonObject(with: fixtureData()) as? [String: Any],
            let events = root["events"] as? [[String: Any]],
            let match = events.first(where: { ($0["id"] as? String)?.caseInsensitiveCompare(id) == .orderedSame })
        else { return nil }

        return try? JSONSerialization.data(withJSONObject: match)
    }
}
