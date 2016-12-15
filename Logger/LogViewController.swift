//
//  LogViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit
import CoreData

class LogViewController: UIViewController, StreamDelegate {
    
    var context: NSManagedObjectContext {
        get {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            return delegate.persistentContainer.viewContext
        }
    }
    
    var robot: Robot? = nil
    var userRequestsSave = false // set to false when not testing
    var streaming = true
    var currentSet: Set? = nil
    var readyToRedrawImage = true
    var currentLog: Log? = nil {
        didSet {
            if let log = currentLog { // localize to prevent concurrency issues
                                      // consider switching to willSet and newValue to avoid duplication
                DispatchQueue.main.async {
                    self.imagesStreamed += 1
                    
                    // raise 10 for smoother FPS indicator, lower for more accuracy
                    if (self.logTimestamps.count >= 10) {
                        self.logTimestamps.remove(at: 0)
                    }
                    self.logTimestamps.append(Date())
                    
                    if self.userRequestsSave {
                        self.imagesSaved += 1
                        self.imagesInCurrentSet += 1
                    }

                    if(self.readyToRedrawImage) {
                        self.readyToRedrawImage = false
                        self.imageView.image = log.fullImage()
                        self.readyToRedrawImage = true
                    }
                }
                
                if userRequestsSave {
                    if currentSet == nil {
                        setsTaken += 1
                        let entity = NSEntityDescription.entity(forEntityName: "Set", in: self.context)
                        currentSet = Set(entity: entity!, insertInto: self.context)
                        currentSet?.setValue(robot?.prettyName ?? "", forKey: "robot")
                        currentSet?.setValue(NSDate(), forKey: "timestamp")
                    }
                    let saveQueue = DispatchQueue(label: "logSave", qos: .userInitiated, attributes: .concurrent)
                    saveQueue.async {
                        log.saveToDatabase(asPartOf: self.currentSet!)
                    }
                }
            }
        }
    }
    
    var imagesStreamed = 0 { didSet { DispatchQueue.main.async { self.imagesStreamedLabel.text = "\(self.imagesStreamed) images streamed" }}}
    var imagesSaved = 0 { didSet { DispatchQueue.main.async { self.imagesSavedLabel.text = "\(self.imagesSaved) images saved" }}}
    var imagesInCurrentSet = 0 { didSet { DispatchQueue.main.async { self.imagesInCurrentSetLabel.text = "\(self.imagesInCurrentSet) images in current set" }}}
    var setsTaken = 0 { didSet { DispatchQueue.main.async { self.setsTakenLabel.text = "\(self.setsTaken) sets taken" }}}
    
    var connectedToRobot = false {
        didSet {
            
            if robot != nil {
                connectedLabel.text = connectedToRobot ? "Connected to \(robot!.prettyName)" : "Disconnected"
            } else {
                connectedLabel.text = "Something funky is going on"
            }
            
            if connectedToRobot == true {
                connectedLabel.textColor = UIColor.green
            } else {
                connectedLabel.textColor = UIColor.red
                // replace these with colors from style guide
            }
        }
    }
    
    private var logTimestamps = [Date()]
    
    var logsPerSecond: Double { get {
        if let first = logTimestamps.first, let last = logTimestamps.last {
            return Double(logTimestamps.count) / last.timeIntervalSince(first)
        }
        return 0
    }}
    
    var secondsStreaming = 0 {
        didSet {
            logsPerSecondLabel.text = "\(Double(logsPerSecond).roundTo(places: 2)) logs per second"
            
            switch logsPerSecond {
            case _ where logsPerSecond < 1:
                logsPerSecondLabel.textColor = UIColor.red
            case _ where logsPerSecond >= 1 && logsPerSecond < 2:
                logsPerSecondLabel.textColor = UIColor.orange
            case _ where logsPerSecond >= 2:
                logsPerSecondLabel.textColor = UIColor.green
            default:
                logsPerSecondLabel.textColor = UIColor.black
            }
        }
    }
    
    @IBAction func recordButtonTouchDown() {
        recordingLabel.text = "Recording"
        recordingLabel.textColor = UIColor.green
        userRequestsSave = true
    }
    
    
    @IBAction func recordButtonTouchUp() {
        recordingLabel.text = "Not Recording"
        recordingLabel.textColor = UIColor.red
        userRequestsSave = false
    }
    
    @IBAction func newSet() {
        currentSet = nil
        imagesInCurrentSet = 0
    }
    
    var timer = Timer()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imagesStreamedLabel: UILabel!
    @IBOutlet weak var imagesSavedLabel: UILabel!
    @IBOutlet weak var imagesInCurrentSetLabel: UILabel!
    @IBOutlet weak var setsTakenLabel: UILabel!
    @IBOutlet weak var connectedLabel: UILabel!
    @IBOutlet weak var logsPerSecondLabel: UILabel!
    @IBOutlet weak var recordingLabel: UILabel!
    
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    let binaryCommandToTurnTripointOn: [UInt8] = [0x00, 0x00, 0x00, 0xfe, 0x7b, 0x22, 0x23, 0x5f, 0x4e, 0x42, 0x49, 0x54, 0x45, 0x53, 0x5f, 0x4a, 0x53, 0x4f, 0x4e, 0x5f, 0x4c, 0x4f, 0x47, 0x5f, 0x56, 0x45, 0x52, 0x53, 0x49, 0x4f, 0x4e, 0x5f, 0x22, 0x3a, 0x38, 0x2c, 0x22, 0x48, 0x4f, 0x53, 0x54, 0x5f, 0x4e, 0x41, 0x4d, 0x45, 0x22, 0x3a, 0x22, 0x62, 0x61, 0x74, 0x6d, 0x61, 0x6e, 0x22, 0x2c, 0x22, 0x48, 0x4f, 0x53, 0x54, 0x5f, 0x54, 0x59, 0x50, 0x45, 0x22, 0x3a, 0x22, 0x56, 0x35, 0x52, 0x4f, 0x42, 0x4f, 0x54, 0x22, 0x2c, 0x22, 0x43, 0x4c, 0x41, 0x53, 0x53, 0x22, 0x3a, 0x22, 0x5f, 0x46, 0x6c, 0x61, 0x67, 0x73, 0x5f, 0x22, 0x2c, 0x22, 0x43, 0x52, 0x45, 0x41, 0x54, 0x45, 0x44, 0x5f, 0x57, 0x48, 0x45, 0x4e, 0x22, 0x3a, 0x31, 0x34, 0x38, 0x31, 0x37, 0x36, 0x39, 0x32, 0x36, 0x30, 0x2c, 0x22, 0x48, 0x4f, 0x53, 0x54, 0x5f, 0x41, 0x44, 0x44, 0x52, 0x22, 0x3a, 0x22, 0x6e, 0x2f, 0x61, 0x22, 0x2c, 0x22, 0x42, 0x4c, 0x4f, 0x43, 0x4b, 0x53, 0x22, 0x3a, 0x5b, 0x7b, 0x22, 0x54, 0x59, 0x50, 0x45, 0x22, 0x3a, 0x22, 0x4a, 0x73, 0x6f, 0x6e, 0x22, 0x2c, 0x22, 0x57, 0x48, 0x45, 0x52, 0x45, 0x5f, 0x46, 0x52, 0x4f, 0x4d, 0x22, 0x3a, 0x22, 0x63, 0x72, 0x65, 0x61, 0x74, 0x65, 0x46, 0x6c, 0x61, 0x67, 0x53, 0x74, 0x61, 0x74, 0x65, 0x4c, 0x6f, 0x67, 0x28, 0x29, 0x22, 0x2c, 0x22, 0x49, 0x4d, 0x41, 0x47, 0x45, 0x5f, 0x49, 0x4e, 0x44, 0x45, 0x58, 0x22, 0x3a, 0x2d, 0x31, 0x2c, 0x22, 0x57, 0x48, 0x45, 0x4e, 0x5f, 0x4d, 0x41, 0x44, 0x45, 0x22, 0x3a, 0x33, 0x34, 0x39, 0x33, 0x30, 0x30, 0x30, 0x30, 0x2c, 0x22, 0x4e, 0x55, 0x4d, 0x5f, 0x42, 0x59, 0x54, 0x45, 0x53, 0x22, 0x3a, 0x38, 0x35, 0x37, 0x7d, 0x5d, 0x7d, 0x00, 0x00, 0x03, 0x59, 0x5b, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x34, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x74, 0x72, 0x69, 0x70, 0x6f, 0x69, 0x6e, 0x74, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x74, 0x72, 0x75, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x35, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x74, 0x72, 0x69, 0x70, 0x6f, 0x69, 0x6e, 0x74, 0x5f, 0x62, 0x6f, 0x74, 0x74, 0x6f, 0x6d, 0x5f, 0x6f, 0x6e, 0x6c, 0x79, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x36, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x6c, 0x6f, 0x63, 0x73, 0x77, 0x61, 0x72, 0x6d, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x37, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x73, 0x74, 0x61, 0x74, 0x65, 0x5f, 0x70, 0x6c, 0x61, 0x79, 0x69, 0x6e, 0x67, 0x5f, 0x6f, 0x76, 0x65, 0x72, 0x72, 0x69, 0x64, 0x65, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x38, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x73, 0x74, 0x61, 0x74, 0x65, 0x5f, 0x70, 0x65, 0x6e, 0x61, 0x6c, 0x74, 0x79, 0x5f, 0x6f, 0x76, 0x65, 0x72, 0x72, 0x69, 0x64, 0x65, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x39, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x53, 0x45, 0x4e, 0x53, 0x4f, 0x52, 0x53, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x30, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x47, 0x55, 0x41, 0x52, 0x44, 0x49, 0x41, 0x4e, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x31, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x43, 0x4f, 0x4d, 0x4d, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x32, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x4c, 0x4f, 0x43, 0x41, 0x54, 0x49, 0x4f, 0x4e, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x33, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x4f, 0x44, 0x4f, 0x4d, 0x45, 0x54, 0x52, 0x59, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x34, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x4f, 0x42, 0x53, 0x45, 0x52, 0x56, 0x41, 0x54, 0x49, 0x4f, 0x4e, 0x53, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x35, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x4c, 0x4f, 0x43, 0x41, 0x4c, 0x49, 0x5a, 0x41, 0x54, 0x49, 0x4f, 0x4e, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x36, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x42, 0x41, 0x4c, 0x4c, 0x54, 0x52, 0x41, 0x43, 0x4b, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x37, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x56, 0x49, 0x53, 0x49, 0x4f, 0x4e, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x38, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x6d, 0x75, 0x6c, 0x74, 0x69, 0x62, 0x61, 0x6c, 0x6c, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x31, 0x39, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x74, 0x68, 0x75, 0x6d, 0x62, 0x6e, 0x61, 0x69, 0x6c, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x32, 0x30, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x6c, 0x6f, 0x67, 0x54, 0x6f, 0x46, 0x69, 0x6c, 0x65, 0x73, 0x79, 0x73, 0x74, 0x65, 0x6d, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x66, 0x61, 0x6c, 0x73, 0x65, 0x7d, 0x2c, 0x7b, 0x22, 0x69, 0x6e, 0x64, 0x65, 0x78, 0x22, 0x3a, 0x32, 0x31, 0x2c, 0x22, 0x6e, 0x61, 0x6d, 0x65, 0x22, 0x3a, 0x22, 0x6c, 0x6f, 0x67, 0x54, 0x6f, 0x53, 0x74, 0x72, 0x65, 0x61, 0x6d, 0x22, 0x2c, 0x22, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x3a, 0x74, 0x72, 0x75, 0x65, 0x7d, 0x5d]

    
    func startStream() {
        //*
        print("\(robot?.hostname ?? "error").bowdoin.edu")
        Stream.getStreamsToHost(withName: "\(robot?.hostname ?? "error").bowdoin.edu", port: 30000, inputStream: &inputStream, outputStream: &outputStream)
        
        inputStream!.open()
        outputStream!.open()
 
        print("\(inputStream?.streamError)")
        //*/

        /*
        let path = Bundle.main.path(forResource: "ExampleLog", ofType: "nblog")
        inputStream = InputStream(fileAtPath: path!)
        inputStream!.open()
        */
        
        while(!outputStream!.hasSpaceAvailable) {
            print("Waiting for output stream to be available")
        }
        
        if (outputStream!.hasSpaceAvailable) {
            outputStream!.write(binaryCommandToTurnTripointOn, maxLength: binaryCommandToTurnTripointOn.count)
            print("Wrote output")
        }
        
        let streamQueue = DispatchQueue(label: "robotStream", qos: .userInitiated, attributes: .concurrent)
        streamQueue.async {
        
            while self.inputStream?.streamError == nil && self.streaming {


                if (self.inputStream?.hasBytesAvailable)! {
                    self.connectedToRobot = true

                    var descriptionLengthBuffer = Array<UInt8>(repeating: 0, count: 4)
                    self.inputStream?.read(&descriptionLengthBuffer, maxLength: 4)
                    let descriptionLength = self.numberFromLengthBuffer(descriptionLengthBuffer)
                    
                    var descriptionBuffer = Array<UInt8>(repeating: 0, count: descriptionLength)
                    var bytesRead = 0
                    while bytesRead < descriptionLength {
                        bytesRead += (self.inputStream?.read(&descriptionBuffer + bytesRead, maxLength: descriptionLength - bytesRead))!
                    }
                    let description = String(bytesNoCopy: &descriptionBuffer, length: descriptionLength, encoding: .ascii, freeWhenDone: false)
                    
                    var dataLengthBuffer = Array<UInt8>(repeating: 0, count: 4)
                    self.inputStream?.read(&dataLengthBuffer, maxLength: 4)
                    let dataLength = self.numberFromLengthBuffer(dataLengthBuffer)
                    
                    var dataBuffer = Array<UInt8>(repeating: 0, count: dataLength)
                    bytesRead = 0
                    while bytesRead < dataLength {
                        bytesRead += (self.inputStream?.read(&dataBuffer + bytesRead, maxLength: dataLength - bytesRead))!
                    }
                    
                    print("image \(self.imagesStreamed): description-\(descriptionLength)b data-\(dataLength)b")
                    self.currentLog = Log(header: description!, data: dataBuffer)
                }
            }
            
            self.connectedToRobot = false
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(LogViewController.countUp), userInfo: nil, repeats: true)
    }
    
    // http://stackoverflow.com/a/39694685
    // sketchy af
    func numberFromLengthBuffer(_ buffer: [UInt8]) -> Int {
        return Int(UInt32(bigEndian: buffer.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
            }.pointee))
    }
    
    func countUp() {
        secondsStreaming += 1
    }
    
    func stopStream() {
        timer.invalidate()
        inputStream?.close()
        outputStream?.close()
        streaming = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = robot?.prettyName
        startStream()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        do {
            try context.save()
        } catch {
            print(error)
            
        }
        
        stopStream()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
