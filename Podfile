# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'

target 'herow_sdk_ios' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for herow-sdk-ios
   pod 'CocoaLumberjack/Swift', '3.5.3'
   pod 'SwiftLint'

  target 'herow_sdk_iosTests' do
    # Pods for testing
  end
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      end
    end
  end

end
