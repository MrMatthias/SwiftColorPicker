//  Created by Matthias Schlemm on 05/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//  Licensed under the MIT License.
//  URL: https://github.com/MrMatthias/SwiftColorPicker

import UIKit
import ImageIO

public struct PickerImage {

    var width: Int
    var height: Int
    var hue: CGFloat = 0
    var alpha: CGFloat = 1.0

    let lockQueue = DispatchQueue(label: "PickerImage")
    private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)

    // MARK: Pixel Data struct

    public struct PixelData {
        var a:UInt8 = 255
        var r:UInt8
        var g:UInt8
        var b:UInt8
    }

    var pixelData: [PixelData]

    // MARK: Image generation

    public func getImage() -> UIImage? {
        return self.imageFromARGB32Bitmap(pixels: self.pixelData, width: UInt(self.width), height: UInt(self.height))
    }

    private func imageFromARGB32Bitmap(pixels:[PixelData], width:UInt, height:UInt) -> UIImage? {

        let bitsPerComponent:UInt = 8
        let bitsPerPixel:UInt = 32

        assert(pixels.count == Int(width * height))

        var data = pixels // Copy to mutable []
        guard let providerRef = CGDataProvider(
            data: NSData(bytes: &data, length: data.count * MemoryLayout<PixelData>.size)
            ) else {
                return nil
        }

        guard let cgim = CGImage(width: Int(width),
                                 height: Int(height),
                                 bitsPerComponent: Int(bitsPerComponent),
                                 bitsPerPixel: Int(bitsPerPixel),
                                 bytesPerRow: Int(width) * MemoryLayout<PixelData>.size,
                                 space: rgbColorSpace,
                                 bitmapInfo: bitmapInfo,
                                 provider: providerRef,
                                 decode: nil,
                                 shouldInterpolate: true,
                                 intent: .defaultIntent) else {
                                    return nil
        }

        let image = UIImage(cgImage: cgim)
        return image
    }

    // MARK: Size changes

    mutating func changeSize(width: Int, height: Int) {
        lockQueue.sync() {
            self.width = width
            self.height = height

            let whitePixel = PixelData(a: 255, r: 255, g: 255, b: 255)
            self.pixelData = Array<PixelData>(repeating: whitePixel, count: Int(width * height))

            self.writeColorData(hue: self.hue, alpha: self.alpha)
        }
    }

    // MARK: Lifecycle

    init(width:Int, height:Int) {
        self.width = width
        self.height = height

        let whitePixel = PixelData(a: 255, r: 255, g: 255, b: 255)
        self.pixelData = Array<PixelData>(repeating: whitePixel, count: Int(width * height))

        self.writeColorData(hue: self.hue, alpha: self.alpha)
    }

    // MARK: Generating raw image data

    public mutating func writeColorData(hue: CGFloat, alpha: CGFloat) {
        lockQueue.sync() {
            self.hue = hue
            self.alpha = alpha

            let saturationSteps = self.width
            let brightnessSteps = self.height

            let saturationStepSize: CGFloat = 1.0 / CGFloat(saturationSteps)
            let brightnessStepSize: CGFloat = 1.0 / CGFloat(brightnessSteps)

            var currentBrightnessIndex = 0
            while currentBrightnessIndex < brightnessSteps {

                var currentSaturationIndex = 0
                while currentSaturationIndex < saturationSteps {


                    let currentSaturation = CGFloat(currentSaturationIndex) * saturationStepSize
                    let currentBrightness = CGFloat(currentBrightnessIndex) * brightnessStepSize
                    let color = UIColor(hue: hue,
                                        saturation: currentSaturation,
                                        brightness: currentBrightness,
                                        alpha: alpha)

                    var red: CGFloat = 0
                    var green: CGFloat = 0
                    var blue: CGFloat = 0
                    var alpha: CGFloat = 0
                    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

                    let index = currentBrightnessIndex * width + currentSaturationIndex
                    self.pixelData[index] = PixelData(a: UInt8(alpha*255.0), r: UInt8(red*255.0), g: UInt8(green*255.0), b: UInt8(blue*255.0))

                    currentSaturationIndex += 1
                }

                currentBrightnessIndex += 1
            }
        }
    }

    
}
