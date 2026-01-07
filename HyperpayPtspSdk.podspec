Pod::Spec.new do |s|
  s.name             = 'HyperpayPtspSdk'
  s.version          = '1.0.1'
  s.summary          = 'Hyperpay PTSP Payment SDK for iOS'
  s.description      = 'Complete payment processing SDK with WebView integration for seamless payment experiences'
  
  s.homepage         = 'https://github.com/HyperpayOpenSource/hyperpay-ptsp-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Hyperpay' => 'developer@hyperpay.com' }
  s.source = { :git => 'https://github.com/HyperpayOpenSource/hyperpay-ptsp-ios.git', :tag => s.version.to_s }
  
  s.platform = :ios, '14.0'
  s.ios.deployment_target = '14.0'
  
  s.vendored_frameworks = 'Frameworks/HyperpayPtspSdk.xcframework'
  
  s.dependency 'Flutter'
  
  s.static_framework = true
  s.requires_arc = true
end
