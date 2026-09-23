//
//  EventsLoader.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public protocol EventsLoader {
    typealias Result = Swift.Result<[Event], Error>

    func load(completion: @escaping (Result) -> Void)
}
