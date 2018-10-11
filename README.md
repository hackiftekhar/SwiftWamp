## SwiftWamp - Swift WAMP implementation

SwiftWamp is a WAMP implementation in Swift.
SwiftWamp is a based to [Swamp 0.1.0](https://github.com/iscriptology/swamp/releases/tag/0.1.0)

It currently supports calling and register remote procedures, subscribing on topics, and publishing events. It also supports authentication using ticket & wampcra authentication.

SwiftWamp `0.3.1` use WebSockets as its only available transport, and JSON as its serialization method.

Contributions will be merged gladly!

## Requirements
iOS 8.0

## Installation
SwiftWamp is available through cocoapods.

```ruby
pod "SwiftWamp"
```

to your Podfile.

## Usage
#### Connect to router

```swift
import SwiftWamp

do {
     let url = try "ws://my-router.com:8080/ws".asURL()
     let transport = WebSocketSwampTransport(wsEndpoint: url)

     let session = SwampSession(realm: "router-defined-realm", transport: transport)
     // Set delegate for callbacks
     // swampSession.delegate = <SwampSessionDelegate implementation>

     session.connect()
     session.disconnect()
}
catch {
     print("Invalid url format")
}

```

#### Connect to router using SwiftWebSocket lib and compression

```swift
import SwiftWamp

let transport = SwiftWebSocketTransport(wsEndpoint: "ws://my-router.com:8080/ws", compression: true)

let session = SwampSession(realm: "router-defined-realm", transport: transport)
// Set delegate for callbacks
// swampSession.delegate = <SwampSessionDelegate implementation>

session.connect()
session.disconnect()

```

##### SwampSession constructor parameters
* `realm` - which realm to join
* `transport` - a `SwampTransport` implementation
* `authmethods` `authid` `authrole` `authextra` - See your router's documentation and use accordingly

##### Connection/Disconnection
* `connect()` - Establish transport and perform authentication if configured.
* `disconnect()` - Opposite.

Now you should wait for your delegate's callbacks:

##### SwampSessionDelegate interface
Implement the following methods:

* `func swampSessionHandleChallenge(authMethod: String, extra: [String: Any]) -> String`
  * Fired when a challenge request arrives.
  * You can `return SwampCraAuthHelper.sign("your-secret", extra["challenge"] as! String)` to support `wampcra` auth method.
* `func swampSessionConnected(session: SwampSession, sessionId: Int)`
 * Fired once the session has established and authenticated a session, and has joined the realm successfully. (AKA You may now call, subscribe & publish.)
* `func swampSessionEnded(reason: String)`
 * Fired once the connection has ended.
 * `reason` is usually a WAMP-domain error, but it can also be a textual description of WTF just happened

#### Let's get use it!
* **General note: Lots of callback functions receive args-kwargs pairs, check your other client implementaion to see which of them is utilized, and act accordingly.**
* **Lots of callback functions receive optional queue argument, it's use for call callback with async DispatchQueue.**

##### Subscribing on topics
Subscribing may fire three callbacks:

* `onSuccess` - if subscription has succeeded.
* `onError` - if it has not.
* `onEvent` - if it succeeded, this is fired when the actual event was published.

###### Signature
```swift
public func subscribe(_ topic: String,
                        options: [String: Any] = [:],
                        using queue: DispatchQueue = .main,
                        onSuccess: @escaping SubscribeCallback,
                        onError: @escaping ErrorSubscribeCallback,
                        onEvent: @escaping EventCallback)
```

###### Simple use case:
```swift
session.subscribe("wamp.topic", onSuccess: { subscription in
    // subscription can be stored for subscription.cancel()
    }, onError: { details, error in

    }, onEvent: { details, results, kwResults in
        // Event data is usually in results, but manually check blabla yadayada
    })
```

###### Full use case:
```swift
session.subscribe("wamp.topic", options: ["disclose_me": true],
    onSuccess: { subscription in
        // subscription can be stored for subscription.cancel()
    }, onError: { details, error in
        // handle error
    }, onEvent: { details, results, kwResults in
        // Event data is usually in results, but manually check blabla yadayada
    })
```

##### Publishing events
Publishing may either be called without callbacks (AKA unacknowledged) or with the following two callbacks:

* `onSuccess` - if publishing has succeeded.
* `onError` - if it has not.

###### Signature
```swift
// without acknowledging
public func publish(_ topic: String,
                      options: [String: Any] = [:],
                      args: [Any]? = nil,
                      kwargs: [String: Any]? = nil,
                      using queue: DispatchQueue = .main)
// with acknowledging
public func publish(_ topic: String,
                      options: [String: Any] = [:],
                      args: [Any]? = nil,
                      kwargs: [String: Any]? = nil,
                      using queue: DispatchQueue = .main,
                      onSuccess: @escaping PublishCallback,
                      onError: @escaping ErrorPublishCallback)
```

###### Simple use case:
```swift
session.publish("wamp.topic", args: [1, "argument2"])
```
###### Full use case:
```swift
session.publish("wamp.topic", options: ["disclose_me": true],  args: [1, "argument2"], kwargs: ["arg1": 1, "arg2": "argument2"],
    onSuccess: {
        // Publication has been published!
    }, onError: { details, error in
        // Handle error (What can it be except wamp.error.not_authorized?)
    })
```

##### Calling remote procedures
Calling may fire two callbacks:

* `onSuccess` - If calling has completed without errors.
* `onError` - If the call has failed. (Either in router or in peer client.)

###### Signature
```swift
public func call(_ proc: String,
                   options: [String: Any] = [:],
                   args: [Any]? = nil,
                   kwargs: [String: Any]? = nil,
                   using queue: DispatchQueue = .main,
                   onSuccess: @escaping CallCallback,
                   onError: @escaping ErrorCallCallback)
```

###### Simple use case:
```swift
session.call("wamp.procedure", args: [1, "argument1"],
    onSuccess: { details, results, kwResults in
        // Usually result is in results[0], but do a manual check in your infrastructure
    },
    onError: { details, error, args, kwargs in
        // Handle your error here (You can ignore args kwargs in most cases)
    })
```

###### Full use case:
```swift
session.call("wamp.procedure", options: ["disclose_me": true], args: [1, "argument1"], kwargs: ["arg1": 1, "arg2": "argument2"],
    onSuccess: { details, results, kwResults in
        // Usually result is in results[0], but do a manual check in your infrastructure
    },
    onError: { details, error, args, kwargs in
        // Handle your error here (You can ignore args kwargs in most cases)
    })
```

##### Register remote procedures
Calling may fire three callbacks:

* `onSuccess` - If register has completed without errors.
* `onError` - If the register has failed. (Either in router or in peer client.)
* `onFire` - The function registered

###### Signature
```swift
public func register(_ proc: String,
                          options: [String: Any] = [:],
                          using queue: DispatchQueue = .main,
                          onSuccess: @escaping RegisterCallback,
                          onError: @escaping ErrorRegisterCallback,
                          onFire: @escaping SwampProc)
```

###### Simple use case:
```swift
session.register("wamp.procedure",
    onSuccess: { details, results, kwResults in
        // Usually result is in results[0], but do a manual check in your infrastructure
    },
    onError: { details, error, args, kwargs in
        // Handle your error here (You can ignore args kwargs in most cases)
    },
    onFire: { details, args, kwargs in
        // Make your great code to execute when someone called your procedure here
    },
)
```

## Testing
For now, only integration tests against crossbar exist. I plan to add unit tests in the future.

In order to run the tests:

1. Install [Crossbar](http://crossbar.io/docs/Installation-on-Mac-OS-X/)
2. Go in your shell and type
```bash
cd SwiftWamp_clone_location/
pod install
cd SwiftWampTests/CrossbarInstanceTest
crossbar start
```
3. Open SwiftWamp.xcworkspace
4. Run the tests! (`Product -> Test` or ⌘U)

### Troubleshooting
If for some reason the tests fail, make sure:

* You have Crossbar installed and run
* You have an available port 8080 on your machine

## Roadmap
1. More robust codebase and error handling
2. Clean log system
3. Timeout publish option/retry
4. MessagePack & Raw Sockets
5. More generic and comfortable API
6. Advanced profile features

## Authors

- Yossi Abraham, yo.ab@outlook.com.
- Dany Sousa, danysousa@protonmail.com

## License

MIT because it's `pod lib create` default : [tldrlegal](https://tldrlegal.com).
