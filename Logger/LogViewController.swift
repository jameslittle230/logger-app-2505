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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = robot!.prettyName
        
        let conn = Connection()
        conn.connect(host: "www.example.com", port: 80)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}

class Connection: NSObject, StreamDelegate {
    var inputStream: InputStream?
    var outputStream: OutputStream?
    
    func connect(host: String, port: Int) {
        Stream.getStreamsToHost(withName: "127.0.0.1", port: 30000, inputStream: &inputStream, outputStream: &outputStream)
        
        if inputStream != nil && outputStream != nil {
            // Set delegate
            inputStream!.delegate = self
            outputStream!.delegate = self
            
            // Schedule
            inputStream!.schedule(in: .main, forMode: RunLoopMode.defaultRunLoopMode)
            outputStream!.schedule(in: .main, forMode: RunLoopMode.defaultRunLoopMode)
            
            print("Start open()")
            
            // Open!
            inputStream!.open()
            outputStream!.open()
            
            print(inputStream!.hasBytesAvailable)
//            outputStream?.write("H", maxLength: 1)
        }
    }
    
    func stream(aStream: Stream, handleEvent eventCode: Stream.Event) {
        print("stream")
//        if aStream === inputStream {
//            switch eventCode {
//            case Stream.Event.errorOccurred:
//                print("input: ErrorOccurred: \(aStream.streamError)")
//            case Stream.Event.openCompleted:
//                print("input: OpenCompleted")
//            case Stream.Event.hasBytesAvailable:
//                print("input: HasBytesAvailable")
//                
//                // Here you can `read()` from `inputStream`
//                
//            default:
//                break
//            }
//        }
//        else if aStream === outputStream {
//            switch eventCode {
//            case Stream.Event.errorOccurred:
//                print("output: ErrorOccurred: \(aStream.streamError)")
//            case Stream.Event.openCompleted:
//                print("output: OpenCompleted")
//            case Stream.Event.hasSpaceAvailable:
//                print("output: HasSpaceAvailable")
//                
//                // Here you can write() to `outputStream`
//                
//            default:
//                break
//            }
//        }
    }
}
