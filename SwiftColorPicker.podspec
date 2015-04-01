Pod::Spec.new do |s|
  s.name         = "SwiftColorPicker"
  s.version      = "0.0.1"
  s.summary      = "A Swift HSB Color Picker"
  s.homepage     = "https://github.com/MrMatthias/SwiftColorPicker"
  s.license      = "MIT"
  s.author             = { "Matthias Schlemm" => "matthias@sixpolys.com" }
  s.platform     = :ios
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/MrMatthias/SwiftColorPicker.git", :tag => "0.0.1" }
  s.source_files  = "Source/*.swift"
  s.requires_arc = true
end
