//
//  ColorWell.swift
//
//  Created by Matthias Schlemm on 12/03/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit

@IBDesignable open class ColorWell: UIButton {

    @IBInspectable open var color:UIColor = UIColor.cyan {
        didSet {
            setNeedsDisplay()
        }
    }


    open var previewColor:UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable open var borderColor:UIColor = UIColor.darkGray {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable open var borderWidth:CGFloat = 2 {
        didSet{
            setNeedsDisplay()
        }
    }
    
    func commonInit() {
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        commonInit()
    }

    override open func draw(_ rect: CGRect) {
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: 5.5, y: 5.5, width: 35, height: 35))
        color.setFill()
        ovalPath.fill()

        
        if let col = previewColor {
            let ovalRect = CGRect(x: 5.5, y: 5.5, width: 35, height: 35)
            let ovalPath = UIBezierPath()
            ovalPath.addArc(withCenter: CGPoint(x: ovalRect.midX, y: ovalRect.midY), radius: ovalRect.width / 2, startAngle: -90 * CGFloat(M_PI)/180, endAngle: 90 * CGFloat(M_PI)/180, clockwise: true)
            ovalPath.addLine(to: CGPoint(x: ovalRect.midX, y: ovalRect.midY))
            ovalPath.close()
            
            col.setFill()
            ovalPath.fill()
        }
        
        borderColor.setStroke()
        ovalPath.lineWidth = borderWidth
        ovalPath.stroke()
    }


}
