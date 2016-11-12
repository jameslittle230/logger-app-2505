//
//  LogViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class LogViewController: UIViewController {
    
    var robot: Robot? = nil
    
    var data: [UInt8] = []
    
    var streaming = false

    @IBOutlet weak var count: UILabel!
    
    @IBAction func button(_ sender: UIButton) {
        if !streaming {
            streaming = true
            startStream()
        } else {
            streaming = false
            stopStream()
        }
    }
    
    @IBAction func reset(_ sender: UIButton) {
        count.text = "0"
    }
    
    func startStream() {
        var inputStream: InputStream?
        var outputStream: OutputStream?
        
        Stream.getStreamsToHost(withName: "batman.bowdoin.edu", port: 30000, inputStream: &inputStream, outputStream: &outputStream)
        
        inputStream!.open()
        outputStream!.open()
        
        var readByte :UInt8 = 0
        print(inputStream?.streamError as Any)
        let pollQueue = DispatchQueue(label: "robotPoll", qos: .userInitiated, attributes: .concurrent)
        pollQueue.async {
            while inputStream?.streamError == nil {
                if self.streaming == false {
                    inputStream?.close()
                    outputStream?.close()
                    return
                }
                if (inputStream?.hasBytesAvailable)! {
                    inputStream?.read(&readByte, maxLength: 1)
                    self.data.append(readByte)
                }
            }
        }
    }
    
    func stopStream() {
        self.count.text = String(data.count)
        let string = NSMutableString(capacity: data.count * 2)
        for byte in data {
            string.appendFormat("%c", byte)
        }
        print(string)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = robot?.prettyName
        data.reserveCapacity(1000000)
        
//        var inputStream: InputStream?
//        var outputStream: OutputStream?
//        
//        Stream.getStreamsToHost(withName: "batman.bowdoin.edu", port: 30000, inputStream: &inputStream, outputStream: &outputStream)
//        
//        inputStream!.open()
//        outputStream!.open()
//
//        var readByte :UInt8 = 0
//        print(inputStream?.streamError as Any)
//        while inputStream?.streamError == nil {
//            if (inputStream?.hasBytesAvailable)! {
//                inputStream?.read(&readByte, maxLength: 1)
//                print(readByte)
//            } else {
//                print("No bytes")
//            }
//        }
//        print(inputStream?.streamError as Any)
//        
//        print("Out of the loop")
        
        
//        let conn = Connection()
//        conn.connect(host: "www.example.com", port: 80)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}
