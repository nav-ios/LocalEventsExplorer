//
//  BookmarksRepository.swift
//  LocalEventsExplorer
//
//  Created by Navdeep Rana on 23/09/26.
//

import Combine
import Foundation

protocol BookmarksRepository {
    func loadBookmarkedEventIDs() -> AnyPublisher<Set<UUID>, Error>
    func addBookmark(for eventID: UUID) -> AnyPublisher<Void, Error>
    func removeBookmark(for eventID: UUID) -> AnyPublisher<Void, Error>
}
