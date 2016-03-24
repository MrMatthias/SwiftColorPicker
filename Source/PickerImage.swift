//
//  PickerImage.swift
//  ScribbleKeys
//
//  Created by Matthias Schlemm on 12/06/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit
import ImageIO

public class PickerImage {
    var provider:CGDataProvider!
    var imageSource:CGImageSource?
    var image:UIImage?
    var mutableData:CFMutableDataRef
    var width:Int
    var height:Int
    
    private func createImageFromData(width:Int, height:Int) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        provider = CGDataProviderCreateWithCFData(mutableData)
        imageSource = CGImageSourceCreateWithDataProvider(provider, nil)
        let cgimg = CGImageCreate(Int(width), Int(height), Int(8), Int(32), Int(width) * Int(4),
            colorSpace, bitmapInfo, provider!, nil as  UnsafePointer<CGFloat>, true, CGColorRenderingIntent.RenderingIntentDefault)
        image = UIImage(CGImage: cgimg!)
    }
    
    func changeSize(width:Int, height:Int) {
        self.width = width
        self.height = height
        let size:Int = width * height * 4
        CFDataSetLength(mutableData, size)
        createImageFromData(width, height: height)
    }
    
    init(width:Int, height:Int) {
        self.width = width
        self.height = height
        let size:Int = width * height * 4
        mutableData = CFDataCreateMutable(kCFAllocatorDefault, size)
        createImageFromData(width, height: height)
    }
    
    public func writeColorData(h:CGFloat, a:CGFloat) {

        let d = CFDataGetMutableBytePtr(self.mutableData)
        
        if width == 0 || height == 0 {
            return
        }

        var i:Int = 0
        let h360:CGFloat = ((h == 1 ? 0 : h) * 360) / 60.0
        let sector:Int = Int(floor(h360))
        let f:CGFloat = h360 - CGFloat(sector)
        let f1:CGFloat = 1.0 - f
        var p:CGFloat = 0.0
        var q:CGFloat = 0.0
        var t:CGFloat = 0.0
        let sd:CGFloat = 1.0 / CGFloat(width)
        let vd:CGFloat =  1 / CGFloat(height)
        
        var double_s:CGFloat = 0
        var pf:CGFloat = 0
        let v_range = 0..<height
        let s_range = 0..<width
        
        for v in v_range {
            pf = 255 * CGFloat(v) * vd
            for s in s_range {
                i = (v * width + s) * 4
                d[i] = UInt8(255)
                if s == 0 {
                    q = pf
                    d[i+1] = UInt8(q)
                    d[i+2] = UInt8(q)
                    d[i+3] = UInt8(q)
                    continue
                }
                
                double_s = CGFloat(s) * sd
                p = pf * (1.0 - double_s)
                q = pf * (1.0 - double_s * f)
                t = pf * ( 1.0 - double_s  * f1)
                switch(sector) {
                case 0:
                    d[i+1] = UInt8(pf)
                    d[i+2] = UInt8(t)
                    d[i+3] = UInt8(p)
                case 1:
                    d[i+1] = UInt8(q)
                    d[i+2] = UInt8(pf)
                    d[i+3] = UInt8(p)
                case 2:
                    d[i+1] = UInt8(p)
                    d[i+2] = UInt8(pf)
                    d[i+3] = UInt8(t)
                case 3:
                    d[i+1] = UInt8(p)
                    d[i+2] = UInt8(q)
                    d[i+3] = UInt8(pf)
                case 4:
                    d[i+1] = UInt8(t)
                    d[i+2] = UInt8(p)
                    d[i+3] = UInt8(pf)
                default:
                    d[i+1] = UInt8(pf)
                    d[i+2] = UInt8(p)
                    d[i+3] = UInt8(q)
                }
                
                
            }
        }
    }

    
}