//
//  ColorPicker.swift
//  ScribbleKeys
//
//  Created by Matthias Schlemm on 05/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit
import ImageIO

class ColorPicker: UIView {
    
    class PickerImage {
        var provider:CGDataProvider!
        var imageSource:CGImageSource?
        var dataRef:CFDataRef?
        var image:UIImage?
        var data:[UInt8]
        
        init(data:[UInt8]) {
            self.data = data
        }
    }
    
    lazy var opQueue:NSOperationQueue = {
        return NSOperationQueue()
    }()
    
    var pickerImage1:PickerImage?
    var pickerImage2:PickerImage?
    var lock:NSLock = NSLock()
    
    var _h:Double = 30
    var h:Double {
        set(value) {
            _h = value
            renderBitmap()
        }
        get {
            return _h
        }
    }
    var image:UIImage?
    
    var data1Shown = false
 
    
    override init() {
        super.init()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func renderBitmap() {
        if self.bounds.isEmpty {
            return
        }
        opQueue.cancelAllOperations()
        if !lock.tryLock() {
            return
        }
        
        opQueue.addOperationWithBlock { () -> Void in
            var width = UInt(bounds.width)
            var height = UInt(bounds.height)
            
            // initialize data stores
            if  self.pickerImage1 == nil {
                self.pickerImage1 = PickerImage(data:[UInt8](count: Int(width * height) * Int(4), repeatedValue: UInt8(255)))
                self.pickerImage2 = PickerImage(data:[UInt8](count: Int(width * height) * Int(4), repeatedValue: UInt8(255)))
            }
            
            // Write colors to data array
            if self.data1Shown { self.writeColorData(&(self.pickerImage2!.data)) }
            else { self.writeColorData(&(self.pickerImage1!.data))}
            
            // create images
            if !self.data1Shown && self.pickerImage1!.image == nil {
                self.dataToPickerImage(self.pickerImage1!.data, pickerImage: &self.pickerImage1!, width: width, height: height)
                self.dataToPickerImage(self.pickerImage2!.data, pickerImage: &self.pickerImage2!, width: width, height: height)
            }
            
            // flip images
            self.image = self.data1Shown ? self.pickerImage2!.image! : self.pickerImage1!.image!
            self.data1Shown = !self.data1Shown
            
            // make changes visible
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.setNeedsDisplay()
                self.lock.unlock()
            })
            
        }
      
    }
    
    func writeColorData(inout d:[UInt8]) {
        var width = UInt(bounds.width)
        var height = UInt(bounds.height)
        var i = 0
        var double_h:Double = Double(h) / 60
        var sector:Int = Int(floor(double_h))
        var f:Double = double_h - Double(sector)
        var f1:Double = 1.0 - f
        var p = 0.0
        var q = 0.0
        var t = 0.0
        var sd:Double = 1.0 / 256
        var vd = 1 / 256
        var a:UInt8 = 255
        var double_v:Double = 0
        var double_s:Double = 0
        
        for v in 0..<Int(self.bounds.height) {
            double_v = Double(v)
            for s in 0..<Int(self.bounds.width) {
                double_s = Double(s) * sd
                p = double_v * (1.0 - double_s)
                q = double_v * (1.0 - double_s * f)
                t = double_v * ( 1.0 - double_s  * f1)
                i = (v * Int(width) + s) * 4
                
                switch(sector) {
                case 0:
                    d[i+1] = UInt8(v)
                    d[i+2] = UInt8(t)
                    d[i+3] = UInt8(p)
                case 1:
                    d[i+1] = UInt8(q)
                    d[i+2] = UInt8(v)
                    d[i+3] = UInt8(p)
                case 2:
                    d[i+1] = UInt8(p)
                    d[i+2] = UInt8(v)
                    d[i+3] = UInt8(t)
                case 3:
                    d[i+1] = UInt8(p)
                    d[i+2] = UInt8(q)
                    d[i+3] = UInt8(v)
                case 4:
                    d[i+1] = UInt8(t)
                    d[i+2] = UInt8(p)
                    d[i+3] = UInt8(v)
                default:
                    d[i+1] = UInt8(v)
                    d[i+2] = UInt8(p)
                    d[i+3] = UInt8(q)
                }
                
                
            }
        }
    }
    
    func dataToPickerImage(d:[UInt8],  inout pickerImage:PickerImage, width:UInt, height:UInt) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        pickerImage.dataRef = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, d, d.count as CFIndex, kCFAllocatorDefault)
        
        pickerImage.provider = CGDataProviderCreateWithCFData(pickerImage.dataRef)
        
        pickerImage.imageSource = CGImageSourceCreateWithDataProvider(pickerImage.provider, nil)
        
        var cgimg = CGImageCreate(width, height, 8, 32, width * UInt(4),
            colorSpace, bitmapInfo, pickerImage.provider!, nil, true, kCGRenderingIntentDefault)
        pickerImage.image = UIImage(CGImage: cgimg)
    }

    override func drawRect(rect: CGRect) {

        if let img = image {
            img.drawInRect(rect)
        }
        
    }

}
