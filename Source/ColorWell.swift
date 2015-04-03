//
//  ColorWell.swift
//
//  Created by Matthias Schlemm on 12/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit

public class ColorWell: UIButton {

    private var _color:UIColor = UIColor.blueColor()
    public var color:UIColor {
        set(value) {
            _color = value
            setNeedsDisplay()
        }
        get {
            return _color
        }
    }

    private var _previewColor:UIColor?
    public var previewColor:UIColor? {
        set(value) {
            _previewColor = value
            setNeedsDisplay()
        }
        get {
            return _previewColor
        }
    }
    public var borderColor:UIColor = UIColor.whiteColor()
    
    func commonInit() {
        backgroundColor = UIColor.clearColor()
        opaque = false
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override public func drawRect(rect: CGRect) {
        var ovalPath = UIBezierPath(ovalInRect: CGRectMake(5.5, 5.5, 35, 35))
        color.setFill()
        ovalPath.fill()

        
        if let col = previewColor {
            var ovalRect = CGRectMake(5.5, 5.5, 35, 35)
            var ovalPath = UIBezierPath()
            ovalPath.addArcWithCenter(CGPointMake(ovalRect.midX, ovalRect.midY), radius: ovalRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: 90 * CGFloat(M_PI)/180, clockwise: true)
            ovalPath.addLineToPoint(CGPointMake(ovalRect.midX, ovalRect.midY))
            ovalPath.closePath()
            
            col.setFill()
            ovalPath.fill()
        }
        
        borderColor.setStroke()
        ovalPath.lineWidth = 2
        ovalPath.stroke()
    }


}
