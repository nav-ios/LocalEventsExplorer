//
//  EventsStore.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public typealias CachedEvents = (events: [LocalEvent], timestamp: Date)

public protocol EventsStore {
    typealias DeletionResult = Result<Void, Error>
    typealias InsertionResult = Result<Void, Error>
    typealias RetrievalResult = Result<CachedEvents?, Error>

    func deleteCachedEvents(completion: @escaping (DeletionResult) -> Void)
    func insert(_ events: [LocalEvent], timestamp: Date, completion: @escaping (InsertionResult) -> Void)
    func retrieve(completion: @escaping (RetrievalResult) -> Void)
}
