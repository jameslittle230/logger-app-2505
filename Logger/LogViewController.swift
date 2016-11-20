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
    
    var imagesStreamed = 0
    var imagesSaved = 0
    var imagesInCurrentSet = 0
    var setsTaken = 0
    
    var connectedToRobot = false
    var secondsStreaming = 0
    
    var timer = Timer()
    
    var logsPerSecond: Double {
        get {
            return Double(imagesStreamed) / Double(secondsStreaming)
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
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
        /*
        Stream.getStreamsToHost(withName: "batman.bowdoin.edu", port: 30000, inputStream: &inputStream, outputStream: &outputStream)
        
        inputStream!.open()
        outputStream!.open()
 
        print("\(inputStream?.streamError)")
        */

        let path = Bundle.main.path(forResource: "SmallLog", ofType: "nblog")
        print(path ?? "It doesn't work")
        inputStream = InputStream(fileAtPath: path!)
        inputStream?.delegate = self
        inputStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
        inputStream?.open()
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(LogViewController.countUp), userInfo: nil, repeats: true)
    }
    
    func countUp() {
        secondsStreaming += 1
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            if let stream = inputStream {
                print("\nPulling from stream")
                let log = pullFrom(stream: stream)
                
                // Do this in another thread?
                let image = log?.fullImage()
                imageView.image = image
                
                // Eventually we'll have to save the image too, do we do that
                // in another thread as well?
                
                stopStream()
                print("The log! \(log)")
            }
        default:
            print("Oh no, no bytes available! Might be benign. Some aren't, though. Humph.")
        }
    }
    
    func pullFrom(stream: InputStream) -> Log? {
        // Get the length of the JSON portion
        var jsonLenBuf: [UInt8] = []
        inputStream?.read(&jsonLenBuf, maxLength: 4)
        let jsonLenBigEnd = jsonLenBuf.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
            }.pointee
        let jsonLen = Int(UInt32(bigEndian: jsonLenBigEnd))
        print("Length of the JSON portion: \(jsonLen)")
        
        // Get the JSON object
        var jsonBuf = Array<UInt8>(repeating: 0, count: 2000)
        inputStream?.read(&jsonBuf, maxLength: jsonLen)
        print("jsonBuf len: \(jsonBuf.count)")
        let jsonStr = String(bytesNoCopy: &jsonBuf, length: jsonLen, encoding: .ascii, freeWhenDone: false)
        
        // Get the length of the image portion
        var imgLenBuf: [UInt8] = []
        inputStream?.read(&imgLenBuf, maxLength: 4)
        let imgLenBigEnd = imgLenBuf.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
            }.pointee
        let imgLen = Int(UInt32(bigEndian: imgLenBigEnd))
        print("Length of the Image portion: \(imgLen)")
        
        // Get the JSON object
        var imgBuf = Array<UInt8>(repeating: 0, count: imgLen) // TODO: Allocate less for bottom camera images
        inputStream?.read(&imgBuf, maxLength: imgLen)
        print("imgBuf len: \(imgBuf.count)")
        
        if let header = jsonStr {
            return Log(header: header, image: imgBuf)
        }
        
        return nil
    }
    
    func stopStream() {
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
