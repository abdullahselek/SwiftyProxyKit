platform :ios, '9.0'
use_frameworks!

workspace 'SwiftyProxyKit.xcworkspace'
project 'SwiftyProxyKit.xcodeproj'

target 'SwiftyProxyKit' do
  	target 'SwiftyProxyKitTests' do
    	inherit! :search_paths
    	
    	pod 'Quick'
    	pod 'Nimble'
  	end

end

target 'Sample-iOS' do
	project 'Sample-iOS/Sample-iOS.xcodeproj'
    inherit! :search_paths
    pod 'SwiftyProxyKit', :path => '.'
end
