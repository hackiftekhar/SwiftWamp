#
# Be sure to run `pod lib lint SwiftWamp.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftWamp'
  s.version          = '0.3.1'
  s.summary          = 'WAMP protocol implementation in swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

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
