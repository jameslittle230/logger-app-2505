//
//  RobotSelectionViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

enum RobotVersion {
    case V4
    case V5
}

struct Robot {
    var prettyName: String = ""
    var hostname: String = ""
    var version: RobotVersion
    var connected: Bool = false
}

class RobotSelectionViewController: UITableViewController {
    
    let robots: [Dictionary<String, Robot>] = [
        [
            "Batman": Robot(prettyName: "Batman", hostname: "batman", version: RobotVersion.V5, connected: false),
            "Shehulk": Robot(prettyName: "Shehulk", hostname: "shehulk", version: RobotVersion.V5, connected: false),
        ],[
            "Zoe": Robot(prettyName: "Zoe", hostname: "zoe", version: RobotVersion.V4, connected: false),
        ]
    ]
    
//    var robotArray: [[Robot]] {
//        get {
//            return
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Robots"

        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = Array(robots[indexPath.section].values)[indexPath.row]
        let dequeued: AnyObject = tableView.dequeueReusableCell(withIdentifier: "RobotSelectionCell", for: indexPath)
        let cell = dequeued as! RobotSelectionTableViewCell
        cell.robotName.text = data.prettyName
        return cell
    }
    
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return robots[section].count
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
