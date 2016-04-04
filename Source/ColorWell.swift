//
//  ColorWell.swift
//
//  Created by Matthias Schlemm on 12/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit

@IBDesignable public class ColorWell: UIButton {

    @IBInspectable public var color:UIColor = UIColor.cyanColor() {
        didSet {
            setNeedsDisplay()
        }
    }


    public var previewColor:UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable public var borderColor:UIColor = UIColor.darkGrayColor() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable public var borderWidth:CGFloat = 2 {
        didSet{
            setNeedsDisplay()
        }
    }
    
    func commonInit() {
        backgroundColor = UIColor.clearColor()
        opaque = false
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        commonInit()
    }

    override public func drawRect(rect: CGRect) {
        let ovalPath = UIBezierPath(ovalInRect: CGRectMake(5.5, 5.5, 35, 35))
        color.setFill()
        ovalPath.fill()

        
        if let col = previewColor {
            let ovalRect = CGRectMake(5.5, 5.5, 35, 35)
            let ovalPath = UIBezierPath()
            ovalPath.addArcWithCenter(CGPointMake(ovalRect.midX, ovalRect.midY), radius: ovalRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: 90 * CGFloat(M_PI)/180, clockwise: true)
            ovalPath.addLineToPoint(CGPointMake(ovalRect.midX, ovalRect.midY))
            ovalPath.closePath()
            
            col.setFill()
            ovalPath.fill()
        }
        
        borderColor.setStroke()
        ovalPath.lineWidth = borderWidth
        ovalPath.stroke()
    }


}
