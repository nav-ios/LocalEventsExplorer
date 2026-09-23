//
//  EventsCacheTestHelpers.swift
//  EventsFeedTests
//
//  Created by Navdeep Rana on 22/09/26.
//

import Foundation
import EventsFeed

func uniqueEvent() -> Event {
    return Event(
        id: UUID(),
        title: "any title",
        location: EventLocation(name: "any place", latitude: 43.65, longitude: -79.38),
        time: Date(),
        imageURL: anyURL()
    )
}

func uniqueEvents() -> (models: [Event], local: [LocalEvent]) {
    let models = [uniqueEvent(), uniqueEvent()]
    let local = models.map {
        LocalEvent(
            id: $0.id,
            title: $0.title,
            locationName: $0.location.name,
            latitude: $0.location.latitude,
            longitude: $0.location.longitude,
            time: $0.time,
            imageURL: $0.imageURL
        )
    }
    return (models, local)
}
