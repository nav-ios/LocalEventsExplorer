//
//  LocalEventsLoader.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public final class LocalEventsLoader {
    private let store: EventsStore
    private let currentDate: () -> Date

    public init(store: EventsStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalEventsLoader {
    public typealias SaveResult = Result<Void, Error>

    public func save(_ events: [Event], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedEvents { [weak self] deletionResult in
            guard let self = self else { return }

            switch deletionResult {
            case .success:
                self.cache(events, with: completion)

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func cache(_ events: [Event], with completion: @escaping (SaveResult) -> Void) {
        store.insert(events.toLocal(), timestamp: currentDate()) { [weak self] insertionResult in
            guard self != nil else { return }

            completion(insertionResult)
        }
    }
}

private extension Array where Element == Event {
    func toLocal() -> [LocalEvent] {
        return map {
            LocalEvent(
                id: $0.id,
                title: $0.title,
                locationName: $0.location.name,
                latitude: $0.location.latitude,
                longitude: $0.location.longitude,
                time: $0.time,
                imageURL: $0.imageURL
            )
        }
    }
}
