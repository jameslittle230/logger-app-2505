//
//  Robot.swift
//  Logger
//
//  Created by James Little on 11/5/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation

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
