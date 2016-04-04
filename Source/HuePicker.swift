//
//  HuePicker.swift
//
//  Created by Matthias Schlemm on 06/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit

public class HuePicker: UIView {
    
    var _h:CGFloat = 0.1111
    public var h:CGFloat { // [0,1]
        set(value) {
            _h = min(1, max(0, value))
            currentPoint = CGPointMake(bounds.width * CGFloat(_h), 0)
            handleRect = CGRectMake(currentPoint.x-3, 0, 6, bounds.height)
            setNeedsDisplay()
        }
        get {
            return _h
        }
    }
    var image:UIImage?
    private var data:[UInt8]?
    private var currentPoint = CGPointZero
    private var handleRect = CGRectZero
    public var handleColor:UIColor = UIColor.blackColor()
    
    public var onHueChange:((hue:CGFloat, finished:Bool) -> Void)?
    
    public func setHueFromColor(color:UIColor) {
        var h:CGFloat = 0
        color.getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        self.h = h
    }
    

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        userInteractionEnabled = true
    }
    
    
    func renderBitmap() {
        if bounds.isEmpty {
            return
        }
        
        let width = UInt(bounds.width)
        let height = UInt(bounds.height)
        
        if  data == nil {
            data = [UInt8](count: Int(width * height) * 4, repeatedValue: UInt8(255))
        }

        var p = 0.0
        var q = 0.0
        var t = 0.0

        var i = 0
        //_ = 255
        var double_v:Double = 0
        var double_s:Double = 0
        let widthRatio:Double = 360 / Double(bounds.width)
        var d = data!
        for hi in 0..<Int(bounds.width) {
            let double_h:Double = widthRatio * Double(hi) / 60
            let sector:Int = Int(floor(double_h))
            let f:Double = double_h - Double(sector)
            let f1:Double = 1.0 - f
            double_v = Double(1)
            double_s = Double(1)
            p = double_v * (1.0 - double_s) * 255
            q = double_v * (1.0 - double_s * f) * 255
            t = double_v * ( 1.0 - double_s  * f1) * 255
            let v255 = double_v * 255
            i = hi * 4
            switch(sector) {
            case 0:
                d[i+1] = UInt8(v255)
                d[i+2] = UInt8(t)
                d[i+3] = UInt8(p)
            case 1:
                d[i+1] = UInt8(q)
                d[i+2] = UInt8(v255)
                d[i+3] = UInt8(p)
            case 2:
                d[i+1] = UInt8(p)
                d[i+2] = UInt8(v255)
                d[i+3] = UInt8(t)
            case 3:
                d[i+1] = UInt8(p)
                d[i+2] = UInt8(q)
                d[i+3] = UInt8(v255)
            case 4:
                d[i+1] = UInt8(t)
                d[i+2] = UInt8(p)
                d[i+3] = UInt8(v255)
            default:
                d[i+1] = UInt8(v255)
                d[i+2] = UInt8(p)
                d[i+3] = UInt8(q)
            }
        }
        var sourcei = 0
        for v in 1..<Int(bounds.height) {
            for s in 0..<Int(bounds.width) {
                sourcei = s * 4
                i = (v * Int(width) * 4) + sourcei
                d[i+1] = d[sourcei+1]
                d[i+2] = d[sourcei+2]
                d[i+3] = d[sourcei+3]
            }
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)

        let provider = CGDataProviderCreateWithCFData(NSData(bytes: &d, length: d.count * sizeof(UInt8)))
        let cgimg = CGImageCreate(Int(width), Int(height), 8, 32, Int(width) * Int(sizeof(UInt8) * 4),
            colorSpace, bitmapInfo, provider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
        
        
        image = UIImage(CGImage: cgimg!)
        
    }
    
    private func handleTouch(touch:UITouch, finished:Bool) {
        let point = touch.locationInView(self)
        currentPoint = CGPointMake(max(0, min(bounds.width, point.x)) , 0)
        handleRect = CGRectMake(currentPoint.x-3, 0, 6, bounds.height)
        _h = (1/bounds.width) * currentPoint.x
        onHueChange?(hue: h, finished:finished)
        setNeedsDisplay()
    }
    
    override public func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        handleTouch(touches.first! as UITouch, finished: false)
    }
    
    override public func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        handleTouch(touches.first! as UITouch, finished: false)
    }
    
    override public func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        handleTouch(touches.first! as UITouch, finished: true)
    }
    
    
    override public func drawRect(rect: CGRect) {
        if image == nil {
            renderBitmap()
        }
        if let img = image {
            img.drawInRect(rect)
        }

        drawHueDragHandler(frame: handleRect)
    }
    
    func drawHueDragHandler(frame frame: CGRect) {
        
        //// Polygon Drawing
        let polygonPath = UIBezierPath()
        polygonPath.moveToPoint(CGPointMake(frame.minX + 4, frame.maxY - 6))
        polygonPath.addLineToPoint(CGPointMake(frame.minX + 7.46, frame.maxY))
        polygonPath.addLineToPoint(CGPointMake(frame.minX + 0.54, frame.maxY))
        polygonPath.closePath()
        UIColor.blackColor().setFill()
        polygonPath.fill()
        
        
        //// Polygon 2 Drawing
        let polygon2Path = UIBezierPath()
        polygon2Path.moveToPoint(CGPointMake(frame.minX + 4, frame.minY + 6))
        polygon2Path.addLineToPoint(CGPointMake(frame.minX + 7.46, frame.minY))
        polygon2Path.addLineToPoint(CGPointMake(frame.minX + 0.54, frame.minY))
        polygon2Path.closePath()
        UIColor.whiteColor().setFill()
        polygon2Path.fill()
    }




}
