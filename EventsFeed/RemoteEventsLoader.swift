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
        do {
            let events = try EventsMapper.map(data, from: response)
            return .success(events)
        } catch {
            return .failure(error)
        }
    }
}

final class EventsMapper {
    private struct Root: Decodable {
        let events: [RemoteEvent]
    }

    private struct RemoteEvent: Decodable {
        let id: UUID
        let title: String
        let location: RemoteLocation
        let time: Date
        let imageURL: URL

        var event: Event {
            return Event(
                id: id,
                title: title,
                location: EventLocation(name: location.name, latitude: location.latitude, longitude: location.longitude),
                time: time,
                imageURL: imageURL
            )
        }
    }

    private struct RemoteLocation: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    private static var OK_200: Int { return 200 }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [Event] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard response.statusCode == OK_200, let root = try? decoder.decode(Root.self, from: data) else {
            throw RemoteEventsLoader.Error.invalidData
        }

        return root.events.map { $0.event }
    }
}
