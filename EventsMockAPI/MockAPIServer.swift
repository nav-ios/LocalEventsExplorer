//
//  MockAPIServer.swift
//  EventsMockAPI
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

/// An in-process mock REST server. Routes are matched by HTTP method and path
/// pattern (`/events/:id`), and responses are served through `URLSession`
/// via `MockAPIURLProtocol`, so production networking code runs unchanged.
public final class MockAPIServer {
    public typealias Handler = (MockAPIRequest) -> MockAPIResponse

    private struct Route {
        let method: String
        let pattern: [String]
        let handler: Handler
    }

    public let baseURL: URL
    public let latency: TimeInterval

    private var routes = [Route]()
    private let lock = NSLock()
    private var _simulatedFailure: Error?

    public init(baseURL: URL, latency: TimeInterval = 0) {
        self.baseURL = baseURL
        self.latency = latency
    }

    /// When set, the next request fails with this error instead of hitting a route.
    /// Used to demo and test graceful handling of network failures.
    public var simulatedFailure: Error? {
        get { lock.lock(); defer { lock.unlock() }; return _simulatedFailure }
        set { lock.lock(); defer { lock.unlock() }; _simulatedFailure = newValue }
    }

    public func register(_ method: String, _ path: String, handler: @escaping Handler) {
        lock.lock(); defer { lock.unlock() }
        routes.append(Route(method: method.uppercased(), pattern: MockAPIServer.components(of: path), handler: handler))
    }

    public func handles(_ request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return url.scheme == baseURL.scheme && url.host == baseURL.host && url.port == baseURL.port
    }

    public func response(for request: URLRequest) -> MockAPIResponse {
        guard let url = request.url else { return .notFound }

        let method = (request.httpMethod ?? "GET").uppercased()
        let path = MockAPIServer.components(of: url.path)

        lock.lock()
        let candidates = routes
        lock.unlock()

        for route in candidates where route.method == method {
            if let params = MockAPIServer.match(pattern: route.pattern, path: path) {
                let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
                return route.handler(MockAPIRequest(url: url, method: method, pathParameters: params, queryItems: query, body: request.httpBody))
            }
        }

        return .notFound
    }

    private static func components(of path: String) -> [String] {
        return path.split(separator: "/").map(String.init)
    }

    private static func match(pattern: [String], path: [String]) -> [String: String]? {
        guard pattern.count == path.count else { return nil }

        var params = [String: String]()
        for (expected, actual) in zip(pattern, path) {
            if expected.hasPrefix(":") {
                params[String(expected.dropFirst())] = actual
            } else if expected != actual {
                return nil
            }
        }
        return params
    }
}

public struct MockAPIRequest {
    public let url: URL
    public let method: String
    public let pathParameters: [String: String]
    public let queryItems: [URLQueryItem]
    public let body: Data?
}

public struct MockAPIResponse: Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    public static func json(_ body: Data, statusCode: Int = 200) -> MockAPIResponse {
        return MockAPIResponse(statusCode: statusCode, headers: ["Content-Type": "application/json"], body: body)
    }

    public static let notFound = MockAPIResponse(statusCode: 404, headers: ["Content-Type": "application/json"], body: Data(#"{"error":"Not Found"}"#.utf8))
}
