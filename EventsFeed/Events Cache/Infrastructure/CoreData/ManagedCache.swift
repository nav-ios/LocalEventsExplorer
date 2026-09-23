//
//  ManagedCache.swift
//  EventsFeed
//
//  Created by Navdeep Rana on 22/09/26.
//

import CoreData

final class ManagedCache: NSManagedObject {
    static let entityName = "ManagedCache"

    @NSManaged var timestamp: Date
    @NSManaged var events: NSOrderedSet
}

extension ManagedCache {
    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: entityName)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }

    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try deleteCache(in: context)
        return ManagedCache(context: context)
    }

    static func deleteCache(in context: NSManagedObjectContext) throws {
        try find(in: context).map(context.delete).map(context.save)
    }

    var localEvents: [LocalEvent] {
        return events.compactMap { ($0 as? ManagedEvent)?.local }
    }
}
