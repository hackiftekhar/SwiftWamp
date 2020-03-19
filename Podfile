platform :ios, '8.0'

def pods
  inherit! :search_paths
  pod 'SwiftyJSON'
  pod 'Starscream', '~> 3.1.1'
  pod 'CryptoSwift'
  pod 'SwiftWebSocket', :git => 'https://github.com/hackiftekhar/SwiftWebSocket.git', :tag => 'v2.8.1'
end

target 'SwiftWamp' do
  use_frameworks!
  pods

  target 'SwiftWampTests' do
  end

end
