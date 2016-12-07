//
//  Set+CoreDataClass.swift
//  Logger
//
//  Created by James Little on 12/3/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation
import CoreData


public class Set: NSManagedObject {
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func getFirstImage() -> UIImage? {
        if let firstLog = logs?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)])[0] as! ManagedLog? {
            let image = Log(managedLog: firstLog).fullImage()
            return image
        }
        
        return nil
    }
    
    func getSortedLogs() -> [Log] {
        if let managedLogs = logs?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)]) as! [ManagedLog?]? {
            // http://stackoverflow.com/a/33505315/3841018
            let logs = managedLogs.flatMap { Log(managedLog: $0!) }
            return logs
        }
        
        return []
    }
    
    func getSortedImages() -> [UIImage] {
        if let managedLogs = logs?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)]) as! [ManagedLog?]? {
            // http://stackoverflow.com/a/33505315/3841018
            let images = managedLogs.flatMap { Log(managedLog: $0!).fullImage() }
            return images
        }
        
        return []
    }

}
