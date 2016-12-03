//
//  Set+CoreDataProperties.swift
//  Logger
//
//  Created by James Little on 12/3/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation
import CoreData

extension Set {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Set> {
        return NSFetchRequest<Set>(entityName: "Set");
    }

    @NSManaged public var justNow: Bool
    @NSManaged public var robot: String?
    @NSManaged public var scene: String?
    @NSManaged public var softDeleted: Bool
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var uploaded: Bool
    @NSManaged public var venue: String?
    @NSManaged public var logs: NSSet?

}

// MARK: Generated accessors for logs
extension Set {

    @objc(addLogsObject:)
    @NSManaged public func addToLogs(_ value: ManagedLog)

    @objc(removeLogsObject:)
    @NSManaged public func removeFromLogs(_ value: ManagedLog)

    @objc(addLogs:)
    @NSManaged public func addToLogs(_ values: NSSet)

    @objc(removeLogs:)
    @NSManaged public func removeFromLogs(_ values: NSSet)

}
