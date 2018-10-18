Pod::Spec.new do |spec|
  spec.name          = 'PresentTableViewModel'
  spec.version       = '1.0.0'
  spec.license       = { :type => 'Apache 2.0', :file => "LICENSE" }
  spec.homepage      = 'https://github.com/presentco/PresentTableViewModel'
  spec.authors       = { 'Pat Niemeyer' => 'pat@pat.net' }
  spec.summary       = 'Simple, declarative style creation of UITableViews for iOS.'
  spec.source        = { :git => 'https://github.com/presentco/PresentTableViewModel.git', :tag => 'v1.0.0' }
  spec.swift_version = '4.2'

  spec.ios.deployment_target  = '10.0'

  spec.source_files       = 'PresentTableViewModel/*.swift'

  spec.framework      = 'SystemConfiguration'
  spec.ios.framework  = 'UIKit'

  spec.dependency 'Then'
  spec.dependency 'RxCocoa'
end
