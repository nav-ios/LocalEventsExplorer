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
