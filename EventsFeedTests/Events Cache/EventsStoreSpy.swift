//
//  EventsStoreSpy.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation
import EventsFeed

final class EventsStoreSpy: EventsStore {
    enum ReceivedMessage: Equatable {
        case deleteCachedEvents
        case insert([LocalEvent], Date)
        case retrieve
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    private var deletionCompletions = [(DeletionResult) -> Void]()
    private var insertionCompletions = [(InsertionResult) -> Void]()
    private var retrievalCompletions = [(RetrievalResult) -> Void]()

    func deleteCachedEvents(completion: @escaping (DeletionResult) -> Void) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedEvents)
    }

    func insert(_ events: [LocalEvent], timestamp: Date, completion: @escaping (InsertionResult) -> Void) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(events, timestamp))
    }

    func retrieve(completion: @escaping (RetrievalResult) -> Void) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
}
