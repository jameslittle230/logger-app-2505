//
//  Set+CoreDataClass.swift
//  Logger
//
//  Created by James Little on 12/3/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation
import CoreData
import NMSSH

public class Set: NSManagedObject {
    
    var robotHostnames: Dictionary<String, String> = [
        "Batman":  "batman",
        "Shehulk": "shehulk",
        "Wasp":    "wasp",
        "Elektra": "elektra",
        "Brave Little Toaster": "blt",
        "Buzz Lightyear": "buzz"
    ]
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func getFirstImage() -> UIImage? {
        if logs?.count ?? 0 > 0 {
            if let firstLog = logs?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)])[0] as! ManagedLog? {
                let image = Log(managedLog: firstLog).fullImage()
                return image
            }
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
    
    func saveToDover(username: String, password: String) -> Bool {
        if (scene == nil || venue == nil) {
            return false
        }
        let session = NMSSHSession(host: "dover.bowdoin.edu", andUsername: username)
        session?.connect()
        
        if session?.isConnected ?? false {
            session?.authenticate(byPassword: password)
            
            if session?.isAuthorized ?? false {
                let doverPath = "/mnt/research/robocup/logs/" + makeFilePath()
                
                do {
                    try session?.channel.execute("mkdir -p \(doverPath)")
                } catch {
                    print("Could not make directory \(doverPath)")
                }
                
                for managedLog in logs ?? [] {
                    let log = Log(managedLog: managedLog as! ManagedLog)
                    let devicePath = (log.generateFile())!.path
                    print(devicePath)
                    print(doverPath)
                    
                    session?.channel.uploadFile(devicePath, to: doverPath)
                }
                
                do {
                    try session?.channel.execute("chown -R :robocupgrp \(doverPath)")
                } catch {
                    print("Could not change the group of \(doverPath)")
                }
                
                return true
            }
        } else {
            return false
        }
        
        return false
    }
    
    func getFormattedScene() -> String {
        let nonAlphanumericCharacterSet = NSCharacterSet.alphanumerics.inverted
        if let unwrappedScene = scene {
            let strippedReplacement = unwrappedScene.components(separatedBy: nonAlphanumericCharacterSet).joined(separator: "_")
            return strippedReplacement.lowercased()
        } else {
            return "{description}"
        }
    }
    
    func makeFilePath() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd"
        let date = formatter.string(from: timestamp! as Date)
        let formattedScene = getFormattedScene()
        return "\(venue ?? "{venue}")/\(date)/\((robotHostnames[robot!])!)/\(formattedScene)/"
    }
    

}
