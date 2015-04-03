//
//  HuePicker.swift
//
//  Created by Matthias Schlemm on 06/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit

public class HuePicker: UIView {
    
    struct Pixel {
        var a:UInt8 = 255
        var r:UInt8
        var g:UInt8
        var b:UInt8
        init(a:UInt8, r:UInt8, g:UInt8, b:UInt8) {
            self.a = a
            self.r = r
            self.g = g
            self.b = b
        }
    }
    var _h:UInt = 40
    public var h:UInt {
        set(value) {
            _h = max(255, min(0, value))
            currentPoint = CGPointMake((bounds.width / 255) * CGFloat(_h), 0)
            setNeedsDisplay()
        }
        get {
            return _h
        }
    }
    var image:UIImage?
    private var data:[Pixel]?
    private var currentPoint = CGPointZero
    private var handleRect = CGRectZero
    public var handleColor:UIColor = UIColor.blackColor()
    
    public var onHueChange:((hue:UInt, finished:Bool) -> Void)?
    
    public func setHueFromColor(color:UIColor) {
        var h:CGFloat = 0
        color.getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        h *= 255
        self.h = UInt(h)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    
    
    func renderBitmap() {
        layer.zPosition = 2000
        if bounds.isEmpty {
            return
        }
        
        var width = UInt(bounds.width)
        var height = UInt(bounds.height)
        
        if  data == nil {
            data = [Pixel]()
        }

        var p = 0.0
        var q = 0.0
        var t = 0.0

        var i = 0
        var a:UInt8 = 255
        var double_v:Double = 0
        var double_s:Double = 0
        for hi in 0..<Int(bounds.width) {
            var double_h:Double = Double(hi) / 60
            var sector:Int = Int(floor(double_h))
            var f:Double = double_h - Double(sector)
            var f1:Double = 1.0 - f
            double_v = Double(1)
            double_s = Double(1)
            p = double_v * (1.0 - double_s) * 255
            q = double_v * (1.0 - double_s * f) * 255
            t = double_v * ( 1.0 - double_s  * f1) * 255
            
            
            switch(sector) {
            case 0:
                data!.insert(Pixel(a: a, r: UInt8(255), g: UInt8(t), b: UInt8(p)), atIndex: i)
            case 1:
                data!.insert(Pixel(a: a, r: UInt8(q), g: UInt8(255), b: UInt8(p)), atIndex: i)
            case 2:
                data!.insert(Pixel(a: a, r: UInt8(p), g: UInt8(255), b: UInt8(t)), atIndex: i)
            case 3:
                data!.insert(Pixel(a: a, r: UInt8(p), g: UInt8(q), b: UInt8(255)), atIndex: i)
            case 4:
                data!.insert(Pixel(a: a, r: UInt8(t), g: UInt8(p), b: UInt8(255)), atIndex: i)
            default:
                data!.insert(Pixel(a: a, r: UInt8(255), g: UInt8(p), b: UInt8(q)), atIndex: i)
            }
            i = hi
        }
        for v in 1..<Int(bounds.height) {
            
            for s in 0..<Int(bounds.width) {
                data!.insert(data![s], atIndex: v * Int(bounds.width) + s)
                
            }
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
        var d = data!
        let provider = CGDataProviderCreateWithCFData(NSData(bytes: &d, length: data!.count * sizeof(Pixel)))
        var cgimg = CGImageCreate(Int(width), Int(height), 8, 32, Int(width) * Int(sizeof(Pixel)),
            colorSpace, bitmapInfo, provider, nil, true, kCGRenderingIntentDefault)
        
        
        image = UIImage(CGImage: cgimg)
        
    }
    
    private func handleTouch(touch:UITouch, finished:Bool) {
        let point = touch.locationInView(self)
        currentPoint = CGPointMake(max(0, min(bounds.width, point.x)) , 0)
        handleRect = CGRectMake(currentPoint.x-3, 0, 6, bounds.height)
        var fH = (bounds.width / 255) * currentPoint.x
        _h = UInt(fH)
        onHueChange?(hue: h, finished:finished)
        setNeedsDisplay()
    }
    
    override public func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouch(touches.first as! UITouch, finished: false)
    }
    
    override public func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouch(touches.first as! UITouch, finished: false)
    }
    
    override public func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouch(touches.first as! UITouch, finished: true)
    }
    
    
    override public func drawRect(rect: CGRect) {
        if image == nil {
            renderBitmap()
        }
        if let img = image {
            img.drawInRect(rect)
        }
        
        var path = UIBezierPath(roundedRect: handleRect, cornerRadius: 3)
        handleColor.setStroke()
        path.stroke()
    }

}
