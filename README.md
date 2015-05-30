# SwiftColorPicker

![Swift Color Picker Screenshot](/../assets/screenshot1.png?raw=true)

##Installation
###CocoaPod
Podfile:

    use_frameworks!
    pod 'SwiftColorPicker'

##Usage
###Simple Example
Create a Storyboard with 3 views and set the Classes to *ColorWell* (UIButton), *ColorPicker* (UIView) and *HuePicker* (UIView). Wire the Outlets with the following code:

    import SwiftColorPicker

    ...

    @IBOutlet var colorWell:ColorWell?
    @IBOutlet var colorPicker:ColorPicker?
    @IBOutlet var huePicker:HuePicker?

    ...
    // Setup
    pickerController = ColorPickerController(svPickerView: colorPicker!, huePickerView: huePicker!, colorWell: colorWell!)
    pickerController?.color = UIColor.redColor()

    // get color:
    pickerController!.color

    // get color updates:
    pickerController?.onColorChange = {(color, finished) in
        if finished {
          self.view.backgroundColor = UIColor.whiteColor() // reset background color to white
        } else {
            self.view.backgroundColor = color // set background color to current selected color (finger is still down)
        }
    }

##Show case
https://itunes.apple.com/us/app/binary-clock-widget/id965640631

##License
MIT-License
