//
//  RemoteEventsLoader.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public final class RemoteEventsLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = Swift.Result<[Event], Swift.Error>

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .failure:
                completion(.failure(Error.connectivity))
            case let .success((data, response)):
                completion(RemoteEventsLoader.map(data, from: response))
            }
        }
    }

    private static func map(_ data: Data, from response: HTTPURLResponse) -> Result {
        guard response.statusCode == 200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(Error.invalidData)
        }

        return .success(root.events)
    }
}

private struct Root: Decodable {
    let events: [Event]
}
