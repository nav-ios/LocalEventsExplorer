//
//  EventsCachePolicy.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public struct EventsCachePolicy {
    public let maxCacheAge: TimeInterval

    public init(maxCacheAge: TimeInterval) {
        self.maxCacheAge = maxCacheAge
    }

    /// Default TTL for the events API response: 30 minutes.
    public static let thirtyMinutes = EventsCachePolicy(maxCacheAge: 30 * 60)

    /// Used as the offline fallback so the last fetched events are always available.
    public static let neverExpires = EventsCachePolicy(maxCacheAge: .infinity)

    func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard maxCacheAge.isFinite else { return true }

        return date.timeIntervalSince(timestamp) < maxCacheAge
    }
}
