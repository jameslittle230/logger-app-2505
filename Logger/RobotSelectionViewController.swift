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
    
    /** 
     Set to true on viewDidAppear. Used to check if we should automatically
     refresh robots -- we have to do this on ViewDidAppear so the spinner
     will show up properly.
     **/
    var loaded = false

    var refresher: UIRefreshControl!

    var robots: [Dictionary<String, Robot>] = [
        [
            "Batman":  Robot(prettyName: "Batman",               hostname: "batman",  version: RobotVersion.V5, connected: false),
            "Shehulk": Robot(prettyName: "Shehulk",              hostname: "shehulk", version: RobotVersion.V5, connected: false),
            "Wasp":    Robot(prettyName: "Wasp",                 hostname: "wasp",    version: RobotVersion.V5, connected: false),
            "Elektra": Robot(prettyName: "Elektra",              hostname: "elektra", version: RobotVersion.V5, connected: false),
            "BLT":     Robot(prettyName: "Brave Little Toaster", hostname: "blt",     version: RobotVersion.V5, connected: false),
            "Buzz":    Robot(prettyName: "Buzz Lightyear",       hostname: "buzz",    version: RobotVersion.V5, connected: false),
        ],[
            "Zoe":   Robot(prettyName: "Zoe",   hostname: "zoe",   version: RobotVersion.V4, connected: false),
            "Mal":   Robot(prettyName: "Mal",   hostname: "mal",   version: RobotVersion.V4, connected: false),
            "Simon": Robot(prettyName: "Simon", hostname: "simon", version: RobotVersion.V4, connected: false),
            "Wash":  Robot(prettyName: "Wash",  hostname: "wash",  version: RobotVersion.V4, connected: false),
            "River": Robot(prettyName: "River", hostname: "river", version: RobotVersion.V4, connected: false),
        ]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Robots"
        
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Refresh robot status")
        refresher.addTarget(self, action: #selector(RobotSelectionViewController.pollRobots), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresher)
        
        if(fakeLoggingData()) {
            robots[0]["Test"] = Robot(prettyName: "Test", hostname: "test", version: RobotVersion.V5, connected: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !loaded {
            refresher.beginRefreshing()
            tableView.contentOffset = CGPoint(x: 0, y: -150) // Scroll up a bit so we can see the spinner
            pollRobots()
            loaded = true
        }
    }
    
    func pollRobots() {
        refresher.attributedTitle = NSAttributedString(string: "Finding robots...")
        let pollQueue = DispatchQueue(label: "robotPoll", qos: .userInitiated, attributes: .concurrent)
        let pollGroup = DispatchGroup()
        for (index, group) in robots.enumerated() {
            for (name, robot) in group {
                pollQueue.async(group: pollGroup) {
                    self.robots[index][name] = self.poll(robot: robot)
                }
            }
        }

        pollGroup.notify(queue: DispatchQueue.main) {
            self.refresher.endRefreshing()
            self.refresher.attributedTitle = NSAttributedString(string: "Refresh robot status")
            self.tableView.reloadData()
            print("Reloaded that thing that's the tableView")
        }

    }
    
    // Returns an updated robot, including SSH session if connected
    private func poll(robot: Robot) -> Robot {
        var robot = robot
        let session = NMSSHSession(host: robot.hostname, andUsername: "nao")
        session?.connect()
        robot.connected = (session?.isConnected)!
        return robot
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
        cell.robotStatusImage.image = data.connected ? #imageLiteral(resourceName: "RobotConnectedIcon") : #imageLiteral(resourceName: "RobotDisconnectedIcon")
        
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
    
    func fakeLoggingData() -> Bool {
        if let fake = Bundle.main.infoDictionary?["USE_FAKE_LOGGING_DATA"] as? Bool {
            print(fake)
            return fake
        } else {
            return false
        }
    }
}

/**
 
 Footnotes:
 
 [1]
 This clunky structure is repeated at least twice and is used to select a single robot from our dictionary in an array-like fashion. I'm wondering if it could be extracted to a computed property, but I'm not sure how that would work aside from creating an array of V4 robots and an array of V5 robots which isn't particularly futureproof: what if we get V6 robots in a year?
 
**/
