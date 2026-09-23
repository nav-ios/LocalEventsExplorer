//
//  CombineHelpers.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 23/09/26.
//

import Combine
import Foundation

// MARK: - EventsLoader

public extension EventsLoader {
    typealias Publisher = AnyPublisher<[Event], Error>

    func loadPublisher() -> Publisher {
        return Deferred {
            Future(self.load)
        }
        .eraseToAnyPublisher()
    }
}

public extension Publisher where Output == [Event] {
    /// Saves every successful emission into the cache without altering the stream.
    func caching(to cache: LocalEventsLoader) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveOutput: { events in
            cache.save(events) { _ in }
        }).eraseToAnyPublisher()
    }
}

// MARK: - ImageDataLoader

public extension ImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>

    func loadImageDataPublisher(from url: URL) -> Publisher {
        var task: ImageDataLoaderTask?

        return Deferred {
            Future { completion in
                task = self.loadImageData(from: url, completion: completion)
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
        .eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Data {
    func caching(to cache: ImageDataCache, using url: URL) -> AnyPublisher<Output, Failure> {
        return handleEvents(receiveOutput: { data in
            cache.save(data, for: url) { _ in }
        }).eraseToAnyPublisher()
    }
}

// MARK: - BookmarksStore

public extension BookmarksStore {
    func retrieveBookmarkedEventIDsPublisher() -> AnyPublisher<Set<UUID>, Error> {
        return Deferred {
            Future(self.retrieveBookmarkedEventIDs)
        }
        .eraseToAnyPublisher()
    }

    func insertBookmarkPublisher(for eventID: UUID) -> AnyPublisher<Void, Error> {
        return Deferred {
            Future { self.insertBookmark(for: eventID, completion: $0) }
        }
        .eraseToAnyPublisher()
    }

    func deleteBookmarkPublisher(for eventID: UUID) -> AnyPublisher<Void, Error> {
        return Deferred {
            Future { self.deleteBookmark(for: eventID, completion: $0) }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Fallback

public extension Publisher {
    func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        return self.catch { _ in fallbackPublisher() }.eraseToAnyPublisher()
    }
}

// MARK: - Main queue dispatching

public extension Publisher {
    func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
        return receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler).eraseToAnyPublisher()
    }
}

public extension DispatchQueue {
    static var immediateWhenOnMainQueueScheduler: ImmediateWhenOnMainQueueScheduler {
        return ImmediateWhenOnMainQueueScheduler.shared
    }

    /// Delivers synchronously when already on the main queue, otherwise hops to it.
    /// Avoids an extra run loop cycle (and a UI flicker) when the value is already on main.
    struct ImmediateWhenOnMainQueueScheduler: Scheduler {
        public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
        public typealias SchedulerOptions = DispatchQueue.SchedulerOptions

        public var now: SchedulerTimeType { DispatchQueue.main.now }
        public var minimumTolerance: SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }

        static let shared = Self()

        private static let key = DispatchSpecificKey<UInt8>()
        private static let value = UInt8.max

        private init() {
            DispatchQueue.main.setSpecific(key: Self.key, value: Self.value)
        }

        private func isMainQueue() -> Bool {
            return DispatchQueue.getSpecific(key: Self.key) == Self.value
        }

        public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
            guard isMainQueue() else {
                return DispatchQueue.main.schedule(options: options, action)
            }
            action()
        }

        public func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
            DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
        }

        public func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
            DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
        }
    }
}
