//
//  LocalEvent.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation

public struct LocalEvent: Equatable {
    public let id: UUID
    public let title: String
    public let locationName: String
    public let latitude: Double
    public let longitude: Double
    public let time: Date
    public let imageURL: URL

    public init(id: UUID, title: String, locationName: String, latitude: Double, longitude: Double, time: Date, imageURL: URL) {
        self.id = id
        self.title = title
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.time = time
        self.imageURL = imageURL
    }
}
