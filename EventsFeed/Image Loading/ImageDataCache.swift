//
//  ImageDataCache.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public protocol ImageDataCache {
    typealias Result = Swift.Result<Void, Error>

    func save(_ data: Data, for url: URL, completion: @escaping (Result) -> Void)
}
