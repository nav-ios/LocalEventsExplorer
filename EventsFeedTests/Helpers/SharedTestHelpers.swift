//
//  SharedTestHelpers.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "https://any-url.com")!
}

func anyData() -> Data {
    return Data("any data".utf8)
}

func anyNSError() -> NSError {
    return NSError(domain: "any error", code: 0)
}
