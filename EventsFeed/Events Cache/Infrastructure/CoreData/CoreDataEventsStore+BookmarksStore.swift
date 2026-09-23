//
//  CoreDataEventsStore+BookmarksStore.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import CoreData

extension CoreDataEventsStore: BookmarksStore {
    public func retrieveBookmarkedEventIDs(completion: @escaping (BookmarksStore.RetrievalResult) -> Void) {
        perform { context in
            completion(Result {
                try ManagedBookmark.allEventIDs(in: context)
            })
        }
    }

    public func insertBookmark(for eventID: UUID, completion: @escaping (BookmarksStore.UpdateResult) -> Void) {
        perform { context in
            completion(Result {
                guard try ManagedBookmark.find(eventID: eventID, in: context) == nil else { return }

                let bookmark = ManagedBookmark(context: context)
                bookmark.eventID = eventID
                bookmark.createdAt = Date()
                try context.save()
            })
        }
    }

    public func deleteBookmark(for eventID: UUID, completion: @escaping (BookmarksStore.UpdateResult) -> Void) {
        perform { context in
            completion(Result {
                try ManagedBookmark.find(eventID: eventID, in: context).map(context.delete).map(context.save)
            })
        }
    }
}
