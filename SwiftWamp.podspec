Pod::Spec.new do |s|
  s.name             = 'SwiftWamp'
  s.version          = '0.3.6'
  s.summary          = 'WAMP protocol implementation in swift'

  s.description      = <<-DESC
the WAMP WebSocket subprotocol implemented purely in Swift
                       DESC

  s.homepage          = 'https://github.com/hackiftekhar/SwiftWamp'
  s.license           = { :type => 'MIT', :file => 'LICENSE' }
  s.author            = { 'Yossi Abraham' => 'yo.ab@outlook.com', 'Dany Sousa' => 'danysousa@protonmail.com' }
  s.source            = { :git => 'https://github.com/hackiftekhar/SwiftWamp.git', :tag => s.version.to_s }
  s.documentation_url = 'https://github.com/hackiftekhar/SwiftWamp/blob/master/README.md'

  s.platform = :ios, '9.0'
  s.ios.deployment_target = '9.0'

  s.source_files = 'SwiftWamp/**/*.{h,swift}'

  s.dependency 'SwiftyJSON'
  s.dependency 'Starscream', '~> 3.1.1'
  s.dependency 'CryptoSwift'
  s.dependency 'SwiftWebSocket'
end
