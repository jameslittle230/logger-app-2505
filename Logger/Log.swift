//
//  Log.swift
//  Logger
//
//  Created by James Little on 11/16/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation
import UIKit

class Log {
    struct constants {
        let bigImageSize = 100
        let smallImageSize = 10
        let bigImageDimensions = (x: 320, y: 240)
        let smallImageDimensions = (x: 160, y: 120)
    }
    
    var header = ""
    var image: [UInt8] = []
    
    init(fullBinary: [UInt8]) {
        image.reserveCapacity(1000000)
        parse(data: fullBinary)
    }
    
    private func parse(data: [UInt8]) {
        // put header in header string and image in image array
    }
    
    func imageFromData() -> UIImage {
        return UIImage()
    }
    
    func saveToDatabase(asPartOf set: Set) {
        
    }
}

class Set {
    
}
