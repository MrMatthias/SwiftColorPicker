//  Created by Matthias Schlemm on 05/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//  Licensed under the MIT License.
//  URL: https://github.com/MrMatthias/SwiftColorPicker

import ImageIO
import UIKit

@IBDesignable open class ColorPicker: UIView {

    fileprivate var pickerImage1:PickerImage?
    fileprivate var pickerImage2:PickerImage?
    fileprivate var image:UIImage?
    fileprivate var data1Shown = false
    fileprivate lazy var opQueue:OperationQueue = { return OperationQueue() }()
    fileprivate var lock:NSLock = NSLock()
    fileprivate var rerender = false
    open var onColorChange:((_ color:UIColor, _ finished:Bool)->Void)? = nil


    open var a:CGFloat = 1 {
        didSet {
            if a < 0 || a > 1 {
                a = max(0, min(1, a))
            }
        }
    }

    open var h:CGFloat = 0 { // // [0,1]
        didSet {
            if h > 1 || h < 0 {
                h = max(0, min(1, h))
            }
            renderBitmap()
            setNeedsDisplay()
        }

    }
    fileprivate var currentPoint:CGPoint = CGPoint.zero


    open func saturationFromCurrentPoint() -> CGFloat {
        return currentPoint.x
    }

    open func brigthnessFromCurrentPoint() -> CGFloat {
        return currentPoint.y
    }

    open var color:UIColor  {
        set(value) {
            var hue:CGFloat = 1
            var saturation:CGFloat = 1
            var brightness:CGFloat = 1
            var alpha:CGFloat = 1
            value.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            a = alpha
            if hue != h || pickerImage1 == nil {
                self.h = hue
            }
            currentPoint = CGPoint(x: saturation, y: brightness)
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
        isUserInteractionEnabled = true
        clipsToBounds = false
        self.addObserver(self, forKeyPath: "bounds",
                         options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial],
                         context: nil)
    }

    deinit {
        self.removeObserver(self, forKeyPath: "bounds")
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds" {
            if(bounds.isEmpty) {
                return
            }
            if var pImage1 = pickerImage1 {
                pImage1.changeSize(width: Int(self.bounds.width), height: Int(self.bounds.height))
            }
            if var pImage2 = pickerImage2 {
                pImage2.changeSize(width: Int(self.bounds.width), height: Int(self.bounds.height))
            }
            renderBitmap()
            self.setNeedsDisplay()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! as UITouch
        handleTouche(touch, ended: false)
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! as UITouch
        handleTouche(touch, ended: false)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! as UITouch
        handleTouche(touch, ended: true)
    }

    fileprivate func handleColorChange(_ color:UIColor, changing:Bool) {
        if color !== self.color {
            if let handler = onColorChange {
                handler(color, !changing)
            }
            setNeedsDisplay()
        }
    }

    fileprivate func handleTouche(_ touch:UITouch, ended:Bool) {
        // set current point
        let point = touch.location(in: self)
        let x:CGFloat = min(bounds.width, max(0, point.x)) / bounds.width
        let y:CGFloat = min(bounds.height, max(0, point.y)) / bounds.height
        currentPoint = CGPoint(x: x, y: y)
        handleColorChange(pointToColor(currentPoint), changing: !ended)
    }

    fileprivate func pointToColor(_ point:CGPoint) ->UIColor {
        let s:CGFloat = min(1, max(0, point.x))
        let b:CGFloat = min(1, max(0, point.y))
        return UIColor(hue: h, saturation: s, brightness: b, alpha:a)
    }

    fileprivate func renderBitmap() {
        if self.bounds.isEmpty {
            return
        }
        if !lock.try() {
            rerender = true
            return
        }
        rerender = false

        if pickerImage1 == nil {
            self.pickerImage1 = PickerImage(width: Int(bounds.width), height: Int(bounds.height))
            self.pickerImage2 = PickerImage(width: Int(bounds.width), height: Int(bounds.height))
        }
#if !TARGET_INTERFACE_BUILDER
        opQueue.addOperation { () -> Void in
            // Write colors to data array
            if self.data1Shown { self.pickerImage2!.writeColorData(hue: self.h, alpha:self.a) } else { self.pickerImage1!.writeColorData(hue: self.h, alpha:self.a) }


            // flip images
            self.image = self.data1Shown ? self.pickerImage2!.getImage()! : self.pickerImage1!.getImage()!
            self.data1Shown = !self.data1Shown

            // make changes visible
            OperationQueue.main.addOperation({ () -> Void in
                self.setNeedsDisplay()
                self.lock.unlock()
                if self.rerender {
                    self.renderBitmap()
                }
            })
       
        }
        #else
        self.pickerImage1!.writeColorData(hue: self.h, alpha:self.a)
        self.image = self.pickerImage1!.getImage()!
        #endif
    }

    open override func draw(_ rect: CGRect) {
        #if TARGET_INTERFACE_BUILDER
        if pickerImage1 == nil {
            commonInit()
        }
        #endif
        if let img = image {
            img.draw(in: rect)
        }

        //// Oval Drawing
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: currentPoint.x * bounds.width - 5,
                                                   y: currentPoint.y * bounds.height - 5,
                                                   width: 10,
                                                   height: 10))
        UIColor.white.setStroke()
        ovalPath.lineWidth = 1
        ovalPath.stroke()

        //// Oval 2 Drawing
        let oval2Path = UIBezierPath(ovalIn: CGRect(x: currentPoint.x * bounds.width - 4,
                                                    y: currentPoint.y * bounds.height - 4,
                                                    width: 8,
                                                    height: 8))
        UIColor.black.setStroke()
        oval2Path.lineWidth = 1
        oval2Path.stroke()
    }

}
