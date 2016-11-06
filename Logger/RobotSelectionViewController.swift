//
//  RobotSelectionViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit
import NMSSH

class RobotSelectionViewController: UITableViewController {
    
    let robots: [Dictionary<String, Robot>] = [
        [
            "Batman": Robot(prettyName: "Batman", hostname: "batman", version: RobotVersion.V5, connected: true),
            "Shehulk": Robot(prettyName: "Shehulk", hostname: "shehulk", version: RobotVersion.V5, connected: false),
        ],[
            "Zoe": Robot(prettyName: "Zoe", hostname: "zoe", version: RobotVersion.V4, connected: true),
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Robots"
        
        let session = NMSSHSession(host: "batman", andUsername: "nao")
        session?.connect()
        if (session?.isConnected)! {
            session?.authenticateByKeyboardInteractive {(_) in return "hotdawgs"}
            if (session?.isAuthorized)! {
                print("Whoa holy crap it worked")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /* Get the data from the model and put it in the table view */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get the data about the cell we want
        let data = Array(robots[indexPath.section].values)[indexPath.row] /* [1] */
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "RobotSelectionCell", for: indexPath)
        
        // Get the cell to put the data in
        let cell = dequeued as! RobotSelectionTableViewCell
        
        // Set the cell's data from the data source
        cell.robotName.text = data.prettyName
        cell.accessoryType = data.connected ? .disclosureIndicator : .none
        
        return cell
    }
    
    /* Set the section titles */
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "V5 Robots"
        case 1:
            return "V4 Robots"
        default:
            return "You don't know how to count"
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return robots.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return robots[section].count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "robotSelectedSegue":
            let cell = sender as! RobotSelectionTableViewCell
            if let IndexPath = tableView.indexPath(for: cell) {
                let robot = Array(robots[IndexPath.section].values)[IndexPath.row] /* [1] */
                return robot.connected
            }
            
        default:
            break
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "robotSelectedSegue":
                let cell = sender as! RobotSelectionTableViewCell
                if let IndexPath = tableView.indexPath(for: cell) {
                    let seguedToMVC = segue.destination as! LogViewController
                    
                    seguedToMVC.robot = Array(robots[IndexPath.section].values)[IndexPath.row] /* [1] */
                }
            default:
                break
            }
        }
    }

}

/**
 
 Footnotes:
 
 [1]
 This clunky structure is repeated at least twice and is used to select a single robot from our dictionary in an array-like fashion. I'm wondering if it could be extracted to a computed property, but I'm not sure how that would work aside from creating an array of V4 robots and an array of V5 robots which isn't particularly futureproof: what if we get V6 robots in a year?
 
**/
