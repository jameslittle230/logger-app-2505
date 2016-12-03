//
//  ManagedLog+CoreDataProperties.swift
//  Logger
//
//  Created by James Little on 12/3/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation
import CoreData


extension ManagedLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedLog> {
        return NSFetchRequest<ManagedLog>(entityName: "Log");
    }

    @NSManaged public var fullData: NSData?
    @NSManaged public var header: String?
    @NSManaged public var imageBinary: NSData?
    @NSManaged public var softDeleted: Bool
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var set: Set?

}
