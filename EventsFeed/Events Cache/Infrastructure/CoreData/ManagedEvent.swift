//
//  ManagedEvent.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import CoreData

final class ManagedEvent: NSManagedObject {
    static let entityName = "ManagedEvent"

    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var locationName: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var time: Date
    @NSManaged var imageURL: URL
    @NSManaged var cache: ManagedCache
}

extension ManagedEvent {
    static func events(from localEvents: [LocalEvent], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localEvents.map { local in
            let managed = ManagedEvent(context: context)
            managed.id = local.id
            managed.title = local.title
            managed.locationName = local.locationName
            managed.latitude = local.latitude
            managed.longitude = local.longitude
            managed.time = local.time
            managed.imageURL = local.imageURL
            return managed
        })
    }

    var local: LocalEvent {
        return LocalEvent(
            id: id,
            title: title,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            time: time,
            imageURL: imageURL
        )
    }
}
