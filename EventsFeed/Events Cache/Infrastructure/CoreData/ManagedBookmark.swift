//
//  ManagedBookmark.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import CoreData

/// Bookmarks are stored independently from the events cache so a cache refresh
/// never wipes what the user has saved.
final class ManagedBookmark: NSManagedObject {
    static let entityName = "ManagedBookmark"

    @NSManaged var eventID: UUID
    @NSManaged var createdAt: Date
}

extension ManagedBookmark {
    static func find(eventID: UUID, in context: NSManagedObjectContext) throws -> ManagedBookmark? {
        let request = NSFetchRequest<ManagedBookmark>(entityName: entityName)
        request.predicate = NSPredicate(format: "eventID == %@", eventID as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    static func allEventIDs(in context: NSManagedObjectContext) throws -> Set<UUID> {
        let request = NSFetchRequest<ManagedBookmark>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        return Set(try context.fetch(request).map { $0.eventID })
    }
}
