Pod::Spec.new do |s|
    # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.name         = "Herow"
    s.version      = "7.0-SNAPSHOT"
    s.summary      = "herow-sdk-ios: an assets of classes and interfaces "
    s.homepage     = "http://www.herow.io/"
    s.module_name  = 'Herow'

    # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.license      = {
        :type => 'Copyright',
        :text => <<-LICENSE
            Copyright 2017-2019 HEROW, Corp. All rights reserved.
        LICENSE
    }

    # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.author       = { "HEROW, Corp" => "contact@herow.io" }

    # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.platform     = :ios

    # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source       = { :git => "./", :branch => "master" }
    s.vendored_frameworks = 'Herow.framework'
    s.ios.deployment_target = '11.0'
    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }

    # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.default_subspecs = 'Detection'

    # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.dependency 'SwiftLint'

    # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.requires_arc = true
    
    
    s.subspec 'Core' do |ss|
        ss.ios.source_files = 'herow-sdk-ios/common/**/*.swift'
        ss.ios.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
        ss.ios.dependency 'CocoaLumberjack/Swift', '3.5.3 '
        ss.ios.deployment_target = '11.0'     
    end

    s.subspec 'Connection' do |ss|
        ss.ios.source_files = 'herow-sdk-ios/connection/**/*.swift'
        ss.ios.dependency 'Herow/Core'
        ss.ios.deployment_target = '11.0'   
        ss.ios.resources = 'herow-sdk-ios/connection/**/*.plist', 'herow-sdk-ios/connection/**/*.xcdatamodeld'
    end

    s.subspec 'Detection' do |ss|
        ss.ios.source_files = 'herow-sdk-ios/detection/**/*.swift'
        ss.ios.frameworks = 'CoreLocation'
        ss.ios.dependency 'Herow/Connection'
        ss.ios.deployment_target = '11.0'
    end
    
end
