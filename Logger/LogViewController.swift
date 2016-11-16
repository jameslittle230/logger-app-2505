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
    
    let binaryCommandToTurnTripointOn: [UInt8] =
        
        // Section 1 is 0xDF bytes long
        [0x00, 0x00, 0x00, 0xDF] +
        
        // Section 1 is a header string as an array of bytes
        [UInt8]("{\"#_NBITES_JSON_LOG_VERSION_\":8,\"CLASS\":\"NullClass\",\"CREATED_WHEN\":0,\"HOST_TYPE\":\"nbtool-v8\",\"HOST_NAME\":\"computer-james\",\"HOST_ADDR\":\"n/a\",\"BLOCKS\":[{\"TYPE\":\"\",\"WHERE_FROM\":\"\",\"IMAGE_INDEX\":0,\"WHEN_MADE\":0,\"NUM_BYTES\":2}]}".utf8) +
        
        // Section 2 is 0x02 bytes long
        [0x00, 0x00, 0x00, 0x02] +
        
        // Section 2, in its two bytes of glory:
        // 0x04: Tripoint; the log format we want to turn on
        // 0x01: On
        [0x04, 0x01]
    
        // In the future, we could also send similar commands to turn each other log type off for speed purposes

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
