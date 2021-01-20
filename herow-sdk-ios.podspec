# Ios-connectplace-common

Pod::Spec.new do |s|
	# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
	s.name         = "herow-sdk-ios"
	s.version      = "0.1-SNAPSHOT"
	s.summary      = "herow-sdk-ios: an assets of classes and interfaces "
	s.homepage     = "http://www.herow.io/"

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
	s.vendored_frameworks = 'herow-sdk-ios.framework'
	s.ios.deployment_target = '11.0'
	s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }

	# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
	s.source_files =  'herow-sdk-ios', 'herow-sdk-ios/**/*.swift'

	# ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
	s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration'
	s.dependency 'CocoaLumberjack/Swift', '3.5.3'
	s.dependency 'PromiseKit', '6.8.4'
	s.dependency 'PromiseKit/Foundation', '6.8.4'
	s.dependency 'SwiftLint'

	# ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
	s.requires_arc = true
end
