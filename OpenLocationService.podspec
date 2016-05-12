Pod::Spec.new do |s|
  s.name             = "OpenLocationService"
  s.version          = "0.1.0"
  s.summary          = "A short description of OpenLocationService."
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = "https://github.com/knly/OpenLocationService"
  s.license          = 'MIT'
  s.author           = { "Nils Fischer" => "n.fischer@viwid.com" }
  s.source           = { :git => "https://github.com/knly/OpenLocationService.git", :tag => 'v' + s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/OpenLocationService/**/*'
  s.resource_bundle = { 'OpenLocationService' => 'Resources/**/*' }
  
  s.frameworks = 'Foundation', 'UIKit', 'MapKit'
  
  s.dependency 'Evergreen'
  s.dependency 'Moya'
  s.dependency 'PromiseKit/CorePromise'
  s.dependency 'SWXMLHash'
  
end
