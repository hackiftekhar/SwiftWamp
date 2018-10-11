# Change Log
## [0.3.0](https://github.com/pitput/SwiftWamp/releases/tag/0.3.0)
* Compatibility with new Starscream version
* Update dependencies

## [0.3.0](https://github.com/pitput/SwiftWamp/releases/tag/0.3.0)
* Compatibility with latest swift version
* Update dependencies

## [0.2.9](https://github.com/pitput/SwiftWamp/releases/tag/0.2.9)
* Host code in github
* Refactor code
* Improve logs
* Improve docs

## [0.2.8](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.8)
* Fix: Use event.end instead of event.error and event.close 

## [0.2.7](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.7)
* Feat: Add debug mode / logging

## [0.2.6](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.6)
* Feat: Add additional websocket transport using SwiftWebSocket lib

## [0.2.5](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.5)
* Fix: args type for call invocation response

## [0.2.4](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.4)
* Feat: Add optional dispatchQueue used for call callbacks

## [0.2.3](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.3)
* Feat: Add register remote calls

## [0.2.2](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.2)
* Feat: Auto Reconnect option
* Feat: Subscription contain topic name, add function to change event callback for a subscription
* Feat: Add topic name in details subscription event callback if discole is set to true
* Fix: Remove SwampMessage factory and cast switch for perf increase 
* Fix: Change typedef for callbacks

## [0.2.1](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.1)
* Fix: Support Int64 subscribe Ids see [WAMP Id validation](http://autobahn.ws/python/_modules/autobahn/wamp/message.html) 
* Add some unit tests
* Add docstring for SwampSession
* Force use NSNull instead nil for serialization
* Fix: Swift 3 support (AnyObject -> Any)
* Fix: Crash if server isn't reachable

## [0.2.0](https://gitlab.com/danysousa/SwiftWamp/tree/0.2.0)
Use source of [Swamp 0.1.0](https://github.com/iscriptology/swamp/releases/tag/0.1.0) and convert to Swift 3.
