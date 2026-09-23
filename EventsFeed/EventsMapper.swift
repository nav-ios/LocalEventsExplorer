//
//  EventsMapper.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

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
