//
//  ColorPicker.swift
//
//  Created by Matthias Schlemm on 05/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit
import ImageIO

public class ColorPicker: UIView {

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

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        userInteractionEnabled = true
        clipsToBounds = false
        self.addObserver(self, forKeyPath: "bounds", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: nil)
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: "bounds")
    }

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "bounds" {
            if let pImage1 = pickerImage1 {
                pImage1.changeSize(Int(self.bounds.width), height: Int(self.bounds.height))
            }
            if let pImage2 = pickerImage2 {
                pImage2.changeSize(Int(self.bounds.width), height: Int(self.bounds.height))
            }
            renderBitmap()
            self.setNeedsDisplay()
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
        handleTouche(touch, ended: false)
    }
    
    public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
        handleTouche(touch, ended: false)
    }
    
    public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
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
        
        if pickerImage1 == nil {
            self.pickerImage1 = PickerImage(width: Int(bounds.width), height: Int(bounds.height))
            self.pickerImage2 = PickerImage(width: Int(bounds.width), height: Int(bounds.height))
        }
        
        opQueue.addOperationWithBlock { () -> Void in
            // Write colors to data array
            if self.data1Shown { self.pickerImage2!.writeColorData(self.h, a:self.a) }
            else { self.pickerImage1!.writeColorData(self.h, a:self.a)}
            
            
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
    


    public override func drawRect(rect: CGRect) {
        if let img = image {
            img.drawInRect(rect)
        }
        
        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalInRect: CGRectMake(currentPoint.x - 5, currentPoint.y - 5, 10, 10))
        UIColor.whiteColor().setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()
        
        //// Oval 2 Drawing
        let oval2Path = UIBezierPath(ovalInRect: CGRectMake(currentPoint.x - 4, currentPoint.y - 4, 8, 8))
        UIColor.blackColor().setStroke()
        oval2Path.lineWidth = 1
        oval2Path.stroke()
    }

}
