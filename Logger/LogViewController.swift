//
//  LogViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class LogViewController: UIViewController, StreamDelegate {
    
    var robot: Robot? = nil
    var userRequestsSave = false // set to false when not testing
    var currentSet: Set? = nil
    var currentLog: Log? = nil {
        didSet {
            if let log = currentLog { // localize to prevent concurrency issues
                                      // consider switching to willSet and newValue to avoid duplication
                DispatchQueue.main.async {
                    self.imagesStreamed += 1
                    
                    if self.userRequestsSave {
                        self.imagesSaved += 1
                        self.imagesInCurrentSet += 1
                    }
                    self.imageView.image = log.fullImage()
                }
                
                if userRequestsSave {
                    let saveQueue = DispatchQueue(label: "logSave", qos: .userInitiated, attributes: .concurrent)
                    saveQueue.async {
                        log.saveToDatabase(asPartOf: self.currentSet ?? Set())
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
                connectedLabel.text = connectedToRobot ? "Connected to \(robot?.prettyName)" : "Disconnected"
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
    
    var logsPerSecond: Double { get { return Double(imagesStreamed) / Double(secondsStreaming) }}
    
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
        setsTaken += 1
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

    
    func startStream() {
        //*
        Stream.getStreamsToHost(withName: "batman.bowdoin.edu", port: 30000, inputStream: &inputStream, outputStream: &outputStream)
        
        inputStream!.open()
        outputStream!.open()
 
        print("\(inputStream?.streamError)")
        //*/

        /*
        let path = Bundle.main.path(forResource: "ExampleLog", ofType: "nblog")
        inputStream = InputStream(fileAtPath: path!)
        inputStream!.open()
        */
        
        let streamQueue = DispatchQueue(label: "robotStream", qos: .userInitiated, attributes: .concurrent)
        streamQueue.async {
        
            while self.inputStream?.streamError == nil {


                if (self.inputStream?.hasBytesAvailable)! {

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
    
//    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//        switch eventCode {
//        case Stream.Event.hasBytesAvailable:
//            outputStream?.write(binaryCommandToTurnTripointOn, maxLength: binaryCommandToTurnTripointOn.count)
//            if let stream = inputStream {
//                print("\nPulling from stream: \(imagesStreamed + 1)")
//                var log = pullFrom(stream: stream)
//                imagesStreamed += 1
//                
//                // Do this in another thread?
//                let image = log?.fullImage()
//                imageView.image = image
//                
//                // Eventually we'll have to save the image too, do we do that
//                // in another thread as well?
//                if userRequestsSave {
//                    if currentSet == nil {
//                        currentSet = Set()
//                    }
//                    log?.saveToDatabase(asPartOf: currentSet!)
//                }
//                
//                print("The log! \(log)")
//                
//                log = pullFrom(stream: stream)
//            }
//        default:
//            print("Might be benign \(aStream.streamStatus)")
//        }
//    }
    
//    func pullFrom(stream: InputStream) -> Log? {
//        // Get the length of the JSON portion
//        var jsonLenBuf = Array<UInt8>(repeating: 0, count: 4)
//        inputStream?.read(&jsonLenBuf, maxLength: 4)
//        print(jsonLenBuf)
//        let jsonLenBigEnd = jsonLenBuf.withUnsafeBufferPointer {
//            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
//            }.pointee
//        let jsonLen = Int(UInt32(bigEndian: jsonLenBigEnd))
//        print("Length of the JSON portion: \(jsonLen)")
//        
//        // Get the JSON string
//        var jsonBuf = Array<UInt8>(repeating: 0, count: jsonLen)
//        inputStream?.read(&jsonBuf, maxLength: jsonLen)
//        print("jsonBuf len: \(jsonBuf.count)")
//        let jsonStr = String(bytesNoCopy: &jsonBuf, length: jsonLen, encoding: .ascii, freeWhenDone: false)
//        
//        // Get the length of the data portion
//        var dataLenBuf = Array<UInt8>(repeating: 0, count: 4)
//        inputStream?.read(&dataLenBuf, maxLength: 4)
//        print(dataLenBuf)
//        let dataLenBigEnd = dataLenBuf.withUnsafeBufferPointer {
//            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
//            }.pointee
//        let dataLen = Int(UInt32(bigEndian: dataLenBigEnd))
//        print("Length of the data portion: \(dataLen)")
//        
//        // Get the data
//        var dataBuf = Array<UInt8>(repeating: 0, count: dataLen) // TODO: Allocate less for bottom camera images
//        inputStream?.read(&dataBuf, maxLength: dataLen)
//        
//        
//        if let header = jsonStr {
//            return Log(header: header, data: dataBuf)
//        }
//        
//        return nil
//    }
    
    func stopStream() {
        timer.invalidate()
        inputStream?.remove(from: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        inputStream?.close()
        outputStream?.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = robot?.prettyName
        startStream()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        stopStream()
    }

}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
