//
//  ImageDataStore.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public protocol ImageDataStore {
    typealias RetrievalResult = Swift.Result<Data?, Error>
    typealias InsertionResult = Swift.Result<Void, Error>

    func retrieve(dataForURL url: URL, completion: @escaping (RetrievalResult) -> Void)
    func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void)
}
