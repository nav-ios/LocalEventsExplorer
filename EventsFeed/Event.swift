//
//  Event.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public struct Event: Equatable, Decodable {
    public let id: UUID
    public let title: String
    public let location: EventLocation
    public let time: Date
    public let imageURL: URL

    public init(id: UUID, title: String, location: EventLocation, time: Date, imageURL: URL) {
        self.id = id
        self.title = title
        self.location = location
        self.time = time
        self.imageURL = imageURL
    }
}

public struct EventLocation: Equatable, Decodable {
    public let name: String
    public let latitude: Double
    public let longitude: Double

    public init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
