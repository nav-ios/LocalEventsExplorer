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

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](.success(()))
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](.success(()))
    }

    func completeRetrieval(with error: Error, at index: Int = 0) {
        retrievalCompletions[index](.failure(error))
    }

    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        retrievalCompletions[index](.success(.none))
    }

    func completeRetrieval(with events: [LocalEvent], timestamp: Date, at index: Int = 0) {
        retrievalCompletions[index](.success(CachedEvents(events: events, timestamp: timestamp)))
    }
}
