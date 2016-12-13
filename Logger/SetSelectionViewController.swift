//
//  SetSelectionViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit
import CoreData

class SetSelectionViewController: UITableViewController {
    
    var fetchedSets: [[Set]] = [[], []]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Logs"
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let justNowFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Set")
        justNowFetch.predicate = NSPredicate(format: "justNow == YES", [])
        justNowFetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let moreSetsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Set")
        moreSetsFetch.predicate = NSPredicate(format: "justNow == NO", [])
        moreSetsFetch.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            fetchedSets[0] = try context.fetch(justNowFetch) as! [Set]
            fetchedSets[1] = try context.fetch(moreSetsFetch) as! [Set]
        } catch {
            fatalError("Failed to fetch sets: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /* Get the data from the model and put it in the table view */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get the data about the cell we want
        let data = fetchedSets[indexPath.section][indexPath.row]
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "SetSelectionCell", for: indexPath)
        
        // Get the cell to put the data in
        let cell = dequeued as! SetSelectionTableViewCell
        
        // Set the cell's data from the data source
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let dateString = formatter.string(from: data.timestamp as! Date)
        
        
        cell.logPreviewImage.image = data.getFirstImage() ?? UIImage()
        
        // apple patented rounded rectangles so im gonna damn well use them
        cell.logPreviewImage.layer.cornerRadius = 5.0
        cell.logPreviewImage.clipsToBounds = true
        
        cell.setTitle.text = data.scene ?? "Untitled"
        cell.setDescription.text = "\(data.robot ?? "Unknown robot") – \(dateString) – \(data.logs?.count ?? 0) logs"
        
        return cell
    }
    
    /* Set the section titles */
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Sets from just now"
        case 1:
            return "More sets"
        default:
            return "You still don't know how to count"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 {
            return "No sets!"
        }
        return ""
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedSets[section].count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.persistentContainer.viewContext
            
            context.delete(fetchedSets[indexPath.section][indexPath.row])
            print("Deleting \(fetchedSets[indexPath.section][indexPath.row].timestamp!)")
            do {
                try context.save()
            } catch {
                print(error)
            }
            fetchedSets[indexPath.section].remove(at: indexPath.row)
            print("Section \(indexPath.section) is now \(fetchedSets[indexPath.section].count) rows long")
            
            let setsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Set")
            do {
                let setsArray: [Set] = try context.fetch(setsFetch) as! [Set]
                print("In core data, we have \(setsArray.count) sets")
            } catch {
                print("Core Data Error")
            }
            
            
            // http://stackoverflow.com/a/35228192/3841018
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                self.tableView.reloadData()
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
            CATransaction.commit()
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fetchedSets[indexPath.section][indexPath.row].saveToDover(username: "bowdoin-username", password: "bowdoin-password")
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "setSelectedSegue":
                let cell = sender as! SetSelectionTableViewCell
                if let IndexPath = tableView.indexPath(for: cell) {
                    let seguedToMVC = segue.destination as! SetViewController
                    seguedToMVC.set = fetchedSets[IndexPath.section][IndexPath.row]
                }
            default:
                break
            }
        }
    }
    
}
