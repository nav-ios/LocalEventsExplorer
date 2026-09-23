//
//  BookmarksStore.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public protocol BookmarksStore {
    typealias RetrievalResult = Result<Set<UUID>, Error>
    typealias UpdateResult = Result<Void, Error>

    func retrieveBookmarkedEventIDs(completion: @escaping (RetrievalResult) -> Void)
    func insertBookmark(for eventID: UUID, completion: @escaping (UpdateResult) -> Void)
    func deleteBookmark(for eventID: UUID, completion: @escaping (UpdateResult) -> Void)
}
