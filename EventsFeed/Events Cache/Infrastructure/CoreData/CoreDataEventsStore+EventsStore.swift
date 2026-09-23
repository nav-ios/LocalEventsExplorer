//
//  CoreDataEventsStore+EventsStore.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import CoreData

extension CoreDataEventsStore: EventsStore {
    public func retrieve(completion: @escaping (RetrievalResult) -> Void) {
        perform { context in
            completion(Result {
                try ManagedCache.find(in: context).map {
                    CachedEvents(events: $0.localEvents, timestamp: $0.timestamp)
                }
            })
        }
    }

    public func insert(_ events: [LocalEvent], timestamp: Date, completion: @escaping (InsertionResult) -> Void) {
        perform { context in
            completion(Result {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.events = ManagedEvent.events(from: events, in: context)
                try context.save()
            })
        }
    }

    public func deleteCachedEvents(completion: @escaping (DeletionResult) -> Void) {
        perform { context in
            completion(Result {
                try ManagedCache.deleteCache(in: context)
            })
        }
    }
}
