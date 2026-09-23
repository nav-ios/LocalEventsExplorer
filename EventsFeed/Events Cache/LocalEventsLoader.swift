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
    private let policy: EventsCachePolicy

    public init(store: EventsStore, currentDate: @escaping () -> Date, policy: EventsCachePolicy = .thirtyMinutes) {
        self.store = store
        self.currentDate = currentDate
        self.policy = policy
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

extension LocalEventsLoader: EventsLoader {
    public typealias LoadResult = EventsLoader.Result

    public enum LoadError: Swift.Error, Equatable {
        case emptyCache
        case expiredCache
    }

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }

            switch result {
            case let .failure(error):
                completion(.failure(error))

            case .success(.none):
                completion(.failure(LoadError.emptyCache))

            case let .success(.some(cache)) where self.policy.validate(cache.timestamp, against: self.currentDate()):
                completion(.success(cache.events.toModels()))

            case .success:
                completion(.failure(LoadError.expiredCache))
            }
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

private extension Array where Element == LocalEvent {
    func toModels() -> [Event] {
        return map {
            Event(
                id: $0.id,
                title: $0.title,
                location: EventLocation(name: $0.locationName, latitude: $0.latitude, longitude: $0.longitude),
                time: $0.time,
                imageURL: $0.imageURL
            )
        }
    }
}
