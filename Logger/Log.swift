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
        static let bigImageSize = 614586
        static let smallImageSize = 10
        static let bigImageDimensions = (x: 640, y: 480)
        static let smallImageDimensions = (x: 160, y: 120)
    }
    
    public struct RGBPixel {
        var alpha: UInt8 = 255
        var red: UInt8
        var green: UInt8
        var blue: UInt8
    }
    
    public struct YUYVPixels {
        var y1: UInt8
        var u:  UInt8
        var y2: UInt8
        var v:  UInt8
    }
    
    private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    var header = ""
    var image: [UInt8] = []
    var imageWidth = 0
    var imageHeight = 0
    
    init(header: String, image: [UInt8]) {
        self.header = header
        self.image = image
        
        if image.count == constants.bigImageSize {
            self.imageWidth = constants.bigImageDimensions.x
            self.imageHeight = constants.bigImageDimensions.y
        } else {
            print(image.count)
            self.imageWidth = constants.smallImageDimensions.x
            self.imageHeight = constants.smallImageDimensions.y
        }
    }
    
    private func getRGBPixelArray() -> [RGBPixel] {
        var RGBPixelArray: [RGBPixel] = []
        RGBPixelArray.reserveCapacity(100000)
        
        for index in stride(from: 0, to: image.count, by: 4) {
            
            if index + 3 > image.count {
                break
            }
            
            let currentYUYVPixels = YUYVPixels(y1: image[index], u: image[index + 1], y2: image[index + 2], v: image[index + 3])
            let rgbPixelPair = yuyvPixelsToRGBPixelPair(yuyvStruct: currentYUYVPixels)
            
            if RGBPixelArray.count + 2 > Int(imageHeight * imageWidth) {
                break
            }
            
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
    
    public func fullImage() -> UIImage {
        let pixels = getRGBPixelArray()
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        print("Pixels.count is \(pixels.count) and the number of pixels is \(Int(imageWidth * imageHeight))")
        
        assert(pixels.count == Int(imageWidth * imageHeight))
        
        var data = pixels // Copy to mutable []
        let providerRef = CGDataProvider(
            data: NSData(bytes: &data, length: data.count * MemoryLayout<RGBPixel>.size)
        )
        
        let cgim = CGImage(
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
        )
        
        return UIImage(cgImage: cgim!)
    }
    
    func saveToDatabase(asPartOf set: Set) {
        
    }
}

class Set {
    
}
