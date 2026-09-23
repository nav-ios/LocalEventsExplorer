//
//  EventsStoreModel.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import CoreData

/// The Core Data model is built in code so the schema lives next to the managed
/// objects and stays reviewable in a diff, instead of hiding inside an `.xcdatamodeld` bundle.
enum EventsStoreModel {
    static func make() -> NSManagedObjectModel {
        let cache = NSEntityDescription()
        cache.name = ManagedCache.entityName
        cache.managedObjectClassName = NSStringFromClass(ManagedCache.self)

        let event = NSEntityDescription()
        event.name = ManagedEvent.entityName
        event.managedObjectClassName = NSStringFromClass(ManagedEvent.self)

        let timestamp = attribute("timestamp", .dateAttributeType)

        let id = attribute("id", .UUIDAttributeType)
        let title = attribute("title", .stringAttributeType)
        let locationName = attribute("locationName", .stringAttributeType)
        let latitude = attribute("latitude", .doubleAttributeType)
        let longitude = attribute("longitude", .doubleAttributeType)
        let time = attribute("time", .dateAttributeType)
        let imageURL = attribute("imageURL", .URIAttributeType)

        let events = NSRelationshipDescription()
        events.name = "events"
        events.destinationEntity = event
        events.deleteRule = .cascadeDeleteRule
        events.isOrdered = true
        events.minCount = 0
        events.maxCount = 0

        let eventCache = NSRelationshipDescription()
        eventCache.name = "cache"
        eventCache.destinationEntity = cache
        eventCache.deleteRule = .nullifyDeleteRule
        eventCache.minCount = 0
        eventCache.maxCount = 1

        events.inverseRelationship = eventCache
        eventCache.inverseRelationship = events

        cache.properties = [timestamp, events]
        event.properties = [id, title, locationName, latitude, longitude, time, imageURL, eventCache]

        let model = NSManagedObjectModel()
        model.entities = [cache, event]
        return model
    }

    private static func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false
        return attribute
    }
}
