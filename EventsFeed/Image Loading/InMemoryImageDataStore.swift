//
//  InMemoryImageDataStore.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

/// `NSCache` evicts entries under memory pressure and respects the cost limit,
/// so the image cache can never grow unbounded even with many events on screen.
public final class InMemoryImageDataStore: ImageDataStore {
    private let cache = NSCache<NSURL, NSData>()

    public init(totalCostLimitInBytes: Int = 50 * 1024 * 1024) {
        cache.totalCostLimit = totalCostLimitInBytes
    }

    public func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void) {
        completion(.success(cache.object(forKey: url as NSURL) as Data?))
    }

    public func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        completion(.success(()))
    }
}
