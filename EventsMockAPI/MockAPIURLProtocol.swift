//
//  MockAPIURLProtocol.swift
//  EventsMockAPI
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

/// Intercepts `URLSession` requests aimed at a registered `MockAPIServer` and
/// answers them in-process, optionally after a simulated network latency.
public final class MockAPIURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var _server: MockAPIServer?

    static var server: MockAPIServer? {
        get { lock.lock(); defer { lock.unlock() }; return _server }
        set { lock.lock(); defer { lock.unlock() }; _server = newValue }
    }

    public static func register(_ server: MockAPIServer) {
        self.server = server
    }

    public static func unregister() {
        server = nil
    }

    public override class func canInit(with request: URLRequest) -> Bool {
        return server?.handles(request) ?? false
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    public override func startLoading() {
        guard let server = MockAPIURLProtocol.server, let client = client else { return }

        let request = self.request
        let deliver = { [weak self] in
            guard let self = self else { return }

            if let failure = server.simulatedFailure {
                server.simulatedFailure = nil
                client.urlProtocol(self, didFailWithError: failure)
                return
            }

            let response = server.response(for: request)
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: response.statusCode, httpVersion: "HTTP/1.1", headerFields: response.headers)!
            client.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: response.body)
            client.urlProtocolDidFinishLoading(self)
        }

        if server.latency > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + server.latency, execute: deliver)
        } else {
            deliver()
        }
    }

    public override func stopLoading() {}
}

public extension URLSessionConfiguration {
    /// A configuration whose requests to `server` are answered in-process.
    static func mockAPI(_ server: MockAPIServer) -> URLSessionConfiguration {
        MockAPIURLProtocol.register(server)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockAPIURLProtocol.self]
        return configuration
    }
}
