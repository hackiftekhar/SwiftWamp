Pod::Spec.new do |s|
  s.name             = 'SwiftWamp'
  s.version          = '0.3.2'
  s.summary          = 'WAMP protocol implementation in swift'

  s.description      = <<-DESC
the WAMP WebSocket subprotocol implemented purely in Swift
                       DESC

  s.homepage          = 'https://github.com/pitput/SwiftWamp'
  s.license           = { :type => 'MIT', :file => 'LICENSE' }
  s.author            = { 'Yossi Abraham' => 'yo.ab@outlook.com', 'Dany Sousa' => 'danysousa@protonmail.com' }
  s.source            = { :git => 'https://github.com/pitput/SwiftWamp.git', :tag => s.version.to_s }
  s.documentation_url = 'https://github.com/pitput/SwiftWamp/blob/master/README.md'

  s.platform = :ios, '8.0'
  s.ios.deployment_target = '8.0'

  s.source_files = 'SwiftWamp/**/*'

  s.dependency 'SwiftyJSON'
  s.dependency 'Starscream'
  s.dependency 'CryptoSwift'
  s.dependency 'SwiftWebSocket'
end
