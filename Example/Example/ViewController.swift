//
//  ViewController.swift
//  Example
//
//  Created by Matthias Schlemm on 12/05/15.
//  Copyright (c) 2015 Sixpolys. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var colorWell:ColorWell?
    @IBOutlet var colorPicker:ColorPicker?
    @IBOutlet var huePicker:HuePicker?
    var pickerController:ColorPickerController?
    @IBOutlet var label:UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The ColorPickerController handels lets you connect a colorWell, a colorPicker and a huepicker. The ColorPickerController takes care of propagating changes between the individual components.
        pickerController = ColorPickerController(svPickerView: colorPicker!, huePickerView: huePicker!, colorWell: colorWell!)
        //Instead of setting an initial color on all 3 ColorPicker components, the ColorPickerController lets you set a color which will be propagated to the individual components.
        pickerController?.color = UIColor.redColor()
        
        /* you shoudln't interact directly with the individual components unless you want to do customization of the colorPicker itself. You can provide a closure to the pickerController, which is going to be invoked when the user is changing a color. Notice that you will receive intermediate color changes. You can use these by coloring the object the User is actually trying to color, so she/he gets a direct visual feedback on how a color changes the appearance of an object of interet. The ColorWell aids in this process by showing old and new color side-by-side.
        */
        pickerController?.onColorChange = {(color, finished) in

                self.label?.textColor = color  // In this example we simply apply the color to a Label

        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

