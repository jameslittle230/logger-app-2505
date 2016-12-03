//
//  Log.swift
//  Logger
//
//  Created by James Little on 11/16/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Log {
    
    private struct constants {
        static let bigImageSize = 614400
        static let smallImageSize = 10
        static let bigImageDimensions = (x: 640, y: 480)
        static let smallImageDimensions = (x: 320, y: 240)
    }
    
    private struct RGBPixel {
        var alpha: UInt8 = 255
        var red: UInt8
        var green: UInt8
        var blue: UInt8
    }
    
    private struct YUYVPixels {
        var y1: UInt8
        var u:  UInt8
        var y2: UInt8
        var v:  UInt8
    }
    
    private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    private var header = JSON(data: Data()) // initialize with blank json?
    private var headerString = ""
    private var data: [UInt8] = []
    private var image: [UInt8] = []
    private var imageWidth = 0
    private var imageHeight = 0
    
    init(header: String, data: [UInt8]) {
        if let dataFromString = header.data(using: .utf8, allowLossyConversion: false) {
            self.header = JSON(data: dataFromString)
        }
        
        self.headerString = header
        self.data = data
    }
    
    private func getRGBPixelArray(imageData: [UInt8]) -> [RGBPixel] {
        var RGBPixelArray: [RGBPixel] = []
        RGBPixelArray.reserveCapacity(100000)
        
        for index in stride(from: 0, to: imageData.count, by: 4) {
            
            if index + 3 > imageData.count {
                break
            }
            
            let currentYUYVPixels = YUYVPixels(y1: imageData[index], u: imageData[index + 1], y2: imageData[index + 2], v: imageData[index + 3])
            let rgbPixelPair = yuyvPixelsToRGBPixelPair(yuyvStruct: currentYUYVPixels)
            
            RGBPixelArray.append(rgbPixelPair[0])
            RGBPixelArray.append(rgbPixelPair[1])
        }
        
        return RGBPixelArray
    }
    
    private func yuyvPixelsToRGBPixelPair(yuyvStruct: YUYVPixels) -> [RGBPixel] {
        let rgbPixel1 = yuvToRGBPixel(y: yuyvStruct.y1, u: yuyvStruct.u, v: yuyvStruct.v)
        let rgbPixel2 = yuvToRGBPixel(y: yuyvStruct.y2, u: yuyvStruct.u, v: yuyvStruct.v)
        return [rgbPixel1, rgbPixel2]
    }
    
    private func clamp(value: Int, min: Int, max: Int) -> Int {
        
        return value > max ?
            max :
            value < min ?
                min : value
    }
    
    private func yuvToRGBPixel(y: UInt8, u: UInt8, v: UInt8) -> RGBPixel {
        let c = Int(y) - 16
        let d = Int(u) - 128
        let e = Int(v) - 128
        
        assert(clamp(value: 256, min: 0, max: 200) == 200)
        assert(clamp(value: 10, min: 100, max: 500 ) == 100)
        assert(clamp(value: 20, min: 5, max: 35) == 20)
        
        let r = clamp(value: (298*c + 409*e + 128) >> 8,         min: 0, max: 255);
        let g = clamp(value: (298*c - 100*d - 208*e + 128) >> 8, min: 0, max: 255);
        let b = clamp(value: (298*c + 516*d + 128) >> 8,         min: 0, max: 255);
        
        return RGBPixel(alpha: 255, red: UInt8(r), green: UInt8(g), blue: UInt8(b))
    }
    
    private func getImageBinary() -> [UInt8] {
        var imageStartIndex = 0
        var imageEndIndex = 0
        var imageLength = 0
        
        for (_, blockJson):(String, JSON) in header["BLOCKS"] {
            if blockJson["TYPE"] == "YUVImage422" {
                imageLength = blockJson["NUM_BYTES"].intValue
                imageEndIndex = imageStartIndex + blockJson["NUM_BYTES"].intValue
                break
            } else {
                imageStartIndex += blockJson["NUM_BYTES"].intValue
            }
        }
        
        if imageStartIndex >= imageEndIndex {
            return [] // or nil maybe?
        }
        
        // Set width and height values based on image size
        if imageLength == constants.bigImageSize {
            self.imageWidth = constants.bigImageDimensions.x
            self.imageHeight = constants.bigImageDimensions.y
        } else {
            self.imageWidth = constants.smallImageDimensions.x
            self.imageHeight = constants.smallImageDimensions.y
        }
        
        return data[imageStartIndex...imageEndIndex] + [] // to convert type from ArraySlice to Array -- see http://blog.stablekernel.com/swift-subarrays-array-and-arrayslice
        
    }
    
    public func fullImage() -> UIImage? {
        let pixels = getRGBPixelArray(imageData: getImageBinary())
        let bitsPerComponent = 8
        let bitsPerPixel = 32
                
        assert(pixels.count == Int(imageWidth * imageHeight))
        
        var data = pixels // Copy to mutable []
        let providerRef = CGDataProvider(
            data: NSData(bytes: &data, length: data.count * MemoryLayout<RGBPixel>.size)
        )
        
        if let cgim = CGImage(
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: imageWidth * MemoryLayout<RGBPixel>.size,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef!,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent
        ) {
            return UIImage(cgImage: cgim)
        } else {
            return nil
        }
    }
    
    public func toNSData() -> NSData? {
        if let headerBytes = headerString.data(using: .ascii) {
            var headerLength = UInt32(headerBytes.count).bigEndian
            let headerLengthBytes = Data(bytes: &headerLength, count: 4)
            let dataBytes = Data(bytes: data)
            var dataLength = UInt32(dataBytes.count).bigEndian
            let dataLengthBytes = Data(bytes: &dataLength, count: 4)
            
            var bytes = Data()
            bytes.append(headerLengthBytes)
            bytes.append(headerBytes)
            bytes.append(dataLengthBytes)
            bytes.append(dataBytes)
            
            return NSData(data: bytes)
        }
        return nil
    }
    
    public func saveToDatabase(asPartOf set: Set) -> Bool {
        if(headerString.lengthOfBytes(using: .ascii) == 0 ||
            data.count == 0 ||
            image.count == 0) {
            return false
        }
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let newLogEntity = NSEntityDescription.insertNewObject(forEntityName: "Log", into: context)
        
//        newLogEntity.setValue(fullData, forKey: "data")
//        newLogEntity.setValue(timestamp, forKey: "timestamp")
        
        do {
            try context.save()
            print("Saved")
            return true
        } catch {
            // process error
        }
    }
}

public class ManagedLog: NSManagedObject {
    @NSManaged var timestamp: NSDate
    @NSManaged var fullData: NSData
    @NSManaged var softDeleted: Bool
}

class Set {
    @NSManaged var justNow: Bool
    @NSManaged var name: String
    @NSManaged var robot: String
    @NSManaged var scene: String
    @NSManaged var softDeleted: Bool
    @NSManaged var timestamp: NSDate
    @NSManaged var uploaded: Bool
    @NSManaged var venue: String
}
