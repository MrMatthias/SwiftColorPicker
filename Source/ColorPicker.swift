//
//  ColorPicker.swift
//
//  Created by Matthias Schlemm on 05/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit
import ImageIO

@IBDesignable public class ColorPicker: UIView {
    
    private class PickerImage {
        var provider:CGDataProvider!
        var imageSource:CGImageSource?
        var dataRef:CFDataRef?
        var image:UIImage?
        var data:[UInt8]
        
        init(data:[UInt8]) {
            self.data = data
        }
    }
    
    private var pickerImage1:PickerImage?
    private var pickerImage2:PickerImage?
    private var image:UIImage?
    private var data1Shown = false
    private lazy var opQueue:NSOperationQueue = {return NSOperationQueue()}()
    private var lock:NSLock = NSLock()
    private var rerender = false
    public var onColorChange:((color:UIColor, finished:Bool)->Void)? = nil
    

    public var a:CGFloat = 1 {
        didSet {
            if a < 0 || a > 1 {
                a = max(0, min(1, a))
            }
        }
    }

    public var h:CGFloat = 0 { // // [0,1]
        didSet {
            if h > 1 || h < 0 {
                h = max(0, min(1, h))
            }
            renderBitmap()
            setNeedsDisplay()
        }

    }
    private var currentPoint:CGPoint = CGPointZero


    public func saturationFromCurrentPoint() -> CGFloat {
        return (1 / bounds.width) * currentPoint.x
    }
    
    public func brigthnessFromCurrentPoint() -> CGFloat {
        return (1 / bounds.height) * currentPoint.y
    }
    
    public var color:UIColor  {
        set(value) {
            var hue:CGFloat = 1
            var saturation:CGFloat = 1
            var brightness:CGFloat = 1
            var alpha:CGFloat = 1
            value.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            a = alpha
            if hue != h || pickerImage1 === nil {
                self.h = hue
            }
            currentPoint = CGPointMake(saturation * bounds.width, brightness * bounds.height)
            self.setNeedsDisplay()
        }
        get {
            return UIColor(hue: h, saturation: saturationFromCurrentPoint(), brightness: brigthnessFromCurrentPoint(), alpha: a)
        }
    }
 
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    public override func updateConstraints() {
        super.updateConstraints()
    }
    
    func commonInit() {
        userInteractionEnabled = true
        clipsToBounds = false
        
    }

    
    public override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        let touch = touches.first as! UITouch
        handleTouche(touch, ended: false)
    }
    
    public override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        var touch = touches.first as! UITouch
        handleTouche(touch, ended: false)
    }
    
    public override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        var touch = touches.first as! UITouch
        handleTouche(touch, ended: true)
    }
    
    private func handleColorChange(color:UIColor, changing:Bool) {
        if color !== self.color {
            if let handler = onColorChange {
                handler(color: color, finished:!changing)
            }
            setNeedsDisplay()
        }
    }
    
    private func handleTouche(touch:UITouch, ended:Bool) {
        // set current point
        let point = touch.locationInView(self)
        if CGRectContainsPoint(self.bounds, point) {
            currentPoint = point
        } else {
            let x:CGFloat = min(bounds.width, max(0, point.x))
            let y:CGFloat = min(bounds.width, max(0, point.y))
            currentPoint = CGPointMake(x, y)
        }
        handleColorChange(pointToColor(point), changing: !ended)
    }
    
    private func pointToColor(point:CGPoint) ->UIColor {
        let s:CGFloat = min(1, max(0, (1.0 / bounds.width) * point.x))
        let b:CGFloat = min(1, max(0, (1.0 / bounds.height) * point.y))
        return UIColor(hue: h, saturation: s, brightness: b, alpha:a)
    }
    
    private func renderBitmap() {
        if self.bounds.isEmpty {
            return
        }
        if !lock.tryLock() {
            rerender = true
            return
        }
        rerender = false
        var width = UInt(self.bounds.width)
        width = (width == 0) ? 256 : width
        var height = UInt(self.bounds.height)
        height = (height == 0) ? 256 : height
        
        // initialize data stores
        if  self.pickerImage1 == nil {
            self.pickerImage1 = PickerImage(data:[UInt8](count: Int(width * height) * Int(4), repeatedValue: UInt8(255)))
            self.pickerImage2 = PickerImage(data:[UInt8](count: Int(width * height) * Int(4), repeatedValue: UInt8(255)))
        }
        
        // create images
        if !self.data1Shown && self.pickerImage1!.image == nil {
            self.dataToPickerImage(self.pickerImage1!.data, pickerImage: &self.pickerImage1!, width: width, height: height)
            self.dataToPickerImage(self.pickerImage2!.data, pickerImage: &self.pickerImage2!, width: width, height: height)
        }

        opQueue.addOperationWithBlock { () -> Void in
            // Write colors to data array
            if self.data1Shown { self.writeColorData(&(self.pickerImage2!.data)) }
            else { self.writeColorData(&(self.pickerImage1!.data))}
            
            
            // flip images
            self.image = self.data1Shown ? self.pickerImage2!.image! : self.pickerImage1!.image!
            self.data1Shown = !self.data1Shown
            
            // make changes visible
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                self.setNeedsDisplay()
                self.lock.unlock()
                if self.rerender {
                    self.renderBitmap()
                }
            })
            
        }
      
    }
    
    private func writeColorData(d:UnsafeMutablePointer<UInt8>) {
        var width = Int(bounds.width)
        width = (width == 0) ? 256 : width
        var height = Int(bounds.height)
        height = (height == 0) ? 256 : height
        var i:Int = 0
        var h360:CGFloat = ((h == 1 ? 0 : h) * 360) / 60.0
        var sector:Int = Int(floor(h360))
        var f:CGFloat = h360 - CGFloat(sector)
        var f1:CGFloat = 1.0 - f
        var p:CGFloat = 0.0
        var q:CGFloat = 0.0
        var t:CGFloat = 0.0
        var sd:CGFloat = 1.0 / bounds.width
        var vd:CGFloat =  1 / bounds.height
        var a:UInt8 = UInt8(self.a * 255)
        var double_s:CGFloat = 0
        var pf:CGFloat = 0
        let v_range = 0..<height
        let s_range = 0..<width
        
        for v in v_range {
            pf = 255 * CGFloat(v) * vd
            for s in s_range {
                i = (v * width + s) * 4
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
    
    private func dataToPickerImage(d:[UInt8],  inout pickerImage:PickerImage, width:UInt, height:UInt) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        pickerImage.dataRef = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, d, d.count as CFIndex, kCFAllocatorDefault)
        
        pickerImage.provider = CGDataProviderCreateWithCFData(pickerImage.dataRef)
        
        pickerImage.imageSource = CGImageSourceCreateWithDataProvider(pickerImage.provider, nil)
        
        var cgimg = CGImageCreate(Int(width), Int(height), Int(8), Int(32), Int(width) * Int(4),
            colorSpace, bitmapInfo, pickerImage.provider!, nil as  UnsafePointer<CGFloat>, true, kCGRenderingIntentDefault)
        pickerImage.image = UIImage(CGImage: cgimg)
    }

    public override func drawRect(rect: CGRect) {
        
        #if !TARGET_INTERFACE_BUILDER
            // this code will run in the app itself
        #else
            if pickerImage1 == nil {
                renderBitmap()
            }
        #endif
        
        if let img = image {
            img.drawInRect(rect)
        }
        
        //// Oval Drawing
        var ovalPath = UIBezierPath(ovalInRect: CGRectMake(currentPoint.x - 5, currentPoint.y - 5, 10, 10))
        UIColor.whiteColor().setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
        
        
        //// Oval 2 Drawing
        var oval2Path = UIBezierPath(ovalInRect: CGRectMake(currentPoint.x - 4, currentPoint.y - 4, 8, 8))
        UIColor.blackColor().setStroke()
        oval2Path.lineWidth = 1
        oval2Path.stroke()
        
        
    }
    
    public override func prepareForInterfaceBuilder() {
        self.renderBitmap()
    }

}
