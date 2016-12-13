//
//  SetDetailViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class SetDetailViewController: UITableViewController {
    
    var desc = "description"
    var venue = "venue"
    let dateSlug = { () -> String in // should this be in the Set class?
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        return "\(String(format: "%02d", month))_\(String(format: "%02d", day))"
    }()
    
    var set: Set?
    
    @IBAction func descriptionUpdate(_ sender: UITextField) {
        if let newDescription = sender.text {
            desc = newDescription.lowercased().replacingOccurrences(of: " ", with: "_")
        } else {
            desc = "description"
        }
        updateHint()
    }
    
    @IBAction func venueUpdate(_ sender: UITextField) {
        if let newVenue = sender.text {
            venue = newVenue
        } else {
            venue = "venue"
        }
        updateHint()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 1): saveLog()
        case IndexPath(row: 0, section: 2): deleteLog()
        default: break // description and venue cells
        }
    }
    
    func saveLog() {
        print("Saving log")
    }
    
    func deleteLog() {
        print("Deleting log")
    }
    
    func updateHint() {
        tableView.footerView(forSection: 1)?.textLabel?.text = "The set will be uploaded to:\nlogs/\(venue)/\(dateSlug)/elektra/\(desc)\n\nUploading a set to Dover deletes the set from the app."
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateHint()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
