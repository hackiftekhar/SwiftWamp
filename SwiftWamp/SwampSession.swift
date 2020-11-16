//
//  SwampSession.swift
//

import Foundation
import SwiftyJSON

// MARK: Call callbacks
/**
 CallCallBack is a typealias for success call callback

 - Parameter details: A [String:Any] containing details about your call
 - Parameter results: An optional [Any] containing all your results
 - Parameter kwResults: [String: Any] Your result indexing by keyString
 */
public typealias CallCallback = (_: [String: Any], _: [Any]?, _: [String: Any]?) -> Void

/**
 ErrorCallCallback is a typealias for fail call callback

 - Parameter details: A [String:Any] containing details about your call
 - Parameter error: A String containing error message
 - Parameter args: An optional [Any] containing all your args
 - Parameter kwargs: [String: Any] Your args indexing by keyString
 */
public typealias ErrorCallCallback = (_: [String: Any], _: String, _: [Any]?, _: [String: Any]?) -> Void

// MARK: Callee callbacks
// For now callee is irrelevant
public typealias RegisterCallback = (_ registration: Registration) -> Void
public typealias ErrorRegisterCallback = (_ details: [String: Any], _ error: String) -> Void
public typealias SwampProc = (_ details: [String: Any], _ args: [Any]?, _ kwargs: [String: Any]?) -> Any
public typealias UnregisterCallback = () -> Void
public typealias ErrorUnregsiterCallback = (_ details: [String: Any], _ error: String) -> Void

// MARK: Subscribe callbacks
/**
 SubscribeCallback is a typealias for success subscribe callback

 - Parameter subscribe: An instance of Subscription describing your subscription (subscribe id, event callback, session...)
 */
public typealias SubscribeCallback = (_ subscription: Subscription) -> Void

/**
 ErrorSubscribeCallback is a typealias for fail subscribe callback

 - Parameter details: A [String:Any] containing details about your subscribe request
 - Parameter error: A String containing error message
 */
public typealias ErrorSubscribeCallback = (_: [String: Any], _: String) -> Void

/**
 EventCallback is called for each published event on the topic

 - Parameter details: A [String:Any] containing details about your subscribe request
 - Parameter result: An optional [Any] containing all the parameters of the published event
 - Parameter kwResults: [String: Any] Your args indexing by keyString
 */
public typealias EventCallback = (_: [String: Any], _: [Any]?, _: [String: Any]?) -> Void

/**
 UnsubscribeCallback is called when your unsubscribe request succeeded
 */
public typealias UnsubscribeCallback = () -> Void

/**
 ErrorUnsubscribeCallback is called if your unsubscribe request failed

 - Parameter details: A [String: Any] containing details about your subscribe request
 - Parameter error: A String containing error message
 */
public typealias ErrorUnsubscribeCallback = (_: [String: Any], _: String) -> Void

// MARK: Publish callbacks

/**
 PublishCallback is called when your publish succeeded
 */
public typealias PublishCallback = () -> Void

/**
 ErrorPublishCallback is called if your publish failed

 - Parameter details: A [String: Any] containing details about your publish request
 - Parameter error: A String containing error message
 */
public typealias ErrorPublishCallback = (_: [String: Any], _: String) -> Void

// TODO: Expose only an interface (like Cancellable) to user

// For now callee is irrelevant
//public class Registration {
//    private let session: SwampSession
//}

public protocol SwampSessionDelegate {
    func swampSessionHandleChallenge(_ authMethod: String, extra: [String: Any]) -> String

    func swampSessionConnected(_ session: SwampSession, sessionId: NSNumber)

    func swampSessionEnded(_ reason: String)
}

/**
 SwampSession is the object connecting all the session data and methods, use this class to connect to the wamp server,
 call, register, unregister, publish, subscribe and unsubscribe
 */

open class SwampSession: SwampTransportDelegate {
    // MARK: Public typealiases

    // MARK: delegate
    /**
     The delegate must implement SwampSessionDelegate and is informed when the session is connected, disconnected or if
     is challenged by the server for an authentication extra data (like ticket)
     */
    open var delegate: SwampSessionDelegate?

    open var enableDebug: Bool = false

    // MARK: Constants
    // No callee role for now
    fileprivate let supportedRoles: [SwampRole] = [SwampRole.Caller, SwampRole.Subscriber, SwampRole.Publisher]
    fileprivate let clientName = "SwiftWamp-dev-0.2.8"

    // MARK: Members
    fileprivate let realm: String
    fileprivate var transport: SwampTransport
    fileprivate let authmethods: [String]?
    fileprivate let authid: String?
    fileprivate let authrole: String?
    fileprivate let authextra: [String: Any]?
    fileprivate var autoReconnect: Bool = false

    // MARK: State members
    fileprivate var currRequestId: Int = 1

    // MARK: Session state
    fileprivate var serializer: SwampSerializer?
    fileprivate var sessionId: NSNumber?
    fileprivate var routerSupportedRoles: [SwampRole]?

    // MARK: Call role
    //                         requestId
    fileprivate var callRequests: [Int: (callback: CallCallback, errorCallback: ErrorCallCallback, queue: DispatchQueue)] = [:]

    // MARK: Registerer role
    //                              requestId
    fileprivate var registerRequests: [Int: (callback: RegisterCallback, errorCallback: ErrorRegisterCallback, eventCallback: SwampProc, proc: String, queue: DispatchQueue)] = [:]
    //                          registration
    fileprivate var registrations: [NSNumber: Registration] = [:]
    fileprivate var unregisterRequests: [Int: (registration: NSNumber, callback: UnregisterCallback, errorCallback: ErrorUnregsiterCallback, queue: DispatchQueue)] = [:]


    // MARK: Subscriber role
    //                              requestId
    fileprivate var subscribeRequests: [Int: (callback: SubscribeCallback, errorCallback: ErrorSubscribeCallback, eventCallback: EventCallback, topic: String, queue: DispatchQueue)] = [:]
    //                          subscription
    fileprivate var subscriptions: [NSNumber: Subscription] = [:]
    open var subscribedTopics: [String] = []
    //                                requestId
    fileprivate var unsubscribeRequests: [Int: (subscription: NSNumber, callback: UnsubscribeCallback, errorCallback: ErrorUnsubscribeCallback, queue: DispatchQueue)] = [:]

    // MARK: Publisher role
    //                            requestId
    fileprivate var publishRequests: [Int: (callback: PublishCallback, errorCallback: ErrorPublishCallback, queue: DispatchQueue)] = [:]

    /**
      The default constructor just save all parameters of the session

      - Parameter realm: String describing the realm name
      - Parameter transport: The transport must implement the SwampTransport protocol, actually you can have an example
        with WebSocketSwampTransport
      - Parameter authmethods: the list of authmethods you support
      - Parameter authid: An optional String communicated to the server during the connection for identify your client
      - Parameter authrole: An optional String communicated to the server during the connection for ask the permissions
      associated to this role
      - Parameter authextra: An optional Dictionary containing all the extra data need to be communicated during the
      connection
     */
    required public init(realm: String,
                         transport: SwampTransport,
                         authmethods: [String]? = nil,
                         authid: String? = nil,
                         authrole: String? = nil,
                         authextra: [String: Any]? = nil) {
        self.realm = realm
        self.transport = transport
        self.authmethods = authmethods
        self.authid = authid
        self.authrole = authrole
        self.authextra = authextra
        self.transport.delegate = self
    }

    // MARK: Public API

    /**
     isConnected is a simple getter of state of session, it's a simple check if the current session have a sessionId

     - Returns: Bool, true if the session is connected to the server
     */
    final public func isConnected() -> Bool {
        return self.sessionId != nil
    }

    /**
     connect use the transport instance to connect client to the server.

     When the connection process is finished, SwampSession call the appropriate SwampSessionDelegate method
     SwampSession is informed by SwampTransportDelegate if the connection failed or succeed
     */
    final public func connect(autoReconnect: Bool = false) {
        self.autoReconnect = autoReconnect
        self.transport.connect()
    }

    /**
     disconnect use the transport instance to disconnect client to the server.

     When the disconnection process is finished, SwampSession call the appropriate SwampSessionDelegate method
     SwampSession is informed by SwampTransportDelegate when the transport is disconnected
    */
    final public func disconnect(_ reason: String = "wamp.error.close_realm") {
        if self.isConnected() {
            self.sendMessage(GoodbyeSwampMessage(details: [:], reason: reason))
        }
    }

    // MARK: Caller role
    /**
     Call is the method to use for remote procedure calls.
     For call a remote procedure, you can specify the procedure name, optional options, optional args/kwargs,
     a success and an error callback.

     - Parameter proc: The procedure name in a String
     - Parameter options: Optional dict containing options requested for this call
     - Parameter args: Optional list [Any]? containing all the argument you communicate for this call
     - Parameter kwargs: Optional dict containing all the argument you communicate for this call indexing by key
     - Parameter onSuccess: it's the function called if the RPC succeed
        the type of this function is the typealias CallCallback, here is the complete signature :
        (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void
     - Parameter onError: it's the function called if the RPC failed
        the type of this function is the typealias ErrorCallCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String, _ args: [Any]?, _ kwargs: [String: Any]?) -> Void
     */
    open func call(_ proc: String,
                   options: [String: Any] = [:],
                   args: [Any]? = nil,
                   kwargs: [String: Any]? = nil,
                   using queue: DispatchQueue = .main,
                   onSuccess: @escaping CallCallback,
                   onError: @escaping ErrorCallCallback) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.call][ERROR] - You try to call \(proc) but you're session id is nil")
            return
        }
        let callRequestId = self.generateRequestId()
        // Tell router to dispatch call
        self.sendMessage(CallSwampMessage(requestId: callRequestId, options: options, proc: proc, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.callRequests[callRequestId] = (callback: onSuccess, errorCallback: onError, queue: queue)
    }

    // MARK: Callee role
     public func register(_ proc: String,
                          options: [String: Any] = [:],
                          using queue: DispatchQueue = .main,
                          onSuccess: @escaping RegisterCallback,
                          onError: @escaping ErrorRegisterCallback,
                          onFire: @escaping SwampProc) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.register][ERROR] - You try to register \(proc) but you're session id is nil")
            return
        }
        // TODO: assert topic is a valid WAMP uri
        let requestId = self.generateRequestId()
        // Tell router to register client on a procedure
        self.sendMessage(RegisterSwampMessage(requestId: requestId, options: options, proc: proc))

        // Store request ID to handle result

        self.registerRequests[requestId] = (callback: onSuccess, errorCallback: onError, eventCallback: onFire, proc: proc, queue: queue)
     }

    // MARK: Subscriber role

    /**
     Subscribe send a subscribe request to the server and, in success case, save the event callback in subscription
     instance.
     For subscribe to a topic, you can specify the topic name, optional options, success/error callback and event
     callback.
     If you subscribe request is accepted, the success callback is called and your event callback must be called for
     each publish received for this topic

     - Parameter topic: A topic name String
     - Parameter options: Optional dict containing options requested for this subscribe
     - Parameter onSuccess: it's the function called if the subscribe request succeed
        the type of this function is the typealias SubscribeCallback, here is the complete signature :
        (_ subscription: Subscription) -> Void
     - Parameter onError: it's the function called if the subscribe request failed
        the type of this function is the typealias ErrorSubscribeCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     - Parameter EventCallback: it's the function called for each publish sent to this topic
        the type of this function is the typealias EventCallback, here is the complete signature :
        (_ details: [String: Any], _ results: [Any]?, _ kwResults: [String: Any]?) -> Void
     */
    open func subscribe(_ topic: String,
                        options: [String: Any] = [:],
                        using queue: DispatchQueue = .main,
                        onSuccess: @escaping SubscribeCallback,
                        onError: @escaping ErrorSubscribeCallback,
                        onEvent: @escaping EventCallback) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.subscribe][ERROR] - You try to subscribe \(topic) but you're session id is nil")
            return
        }
        // TODO: assert topic is a valid WAMP uri
        let subscribeRequestId = self.generateRequestId()
        // Tell router to subscribe client on a topic
        self.sendMessage(SubscribeSwampMessage(requestId: subscribeRequestId, options: options, topic: topic))
        // Store request ID to handle result
        self.subscribeRequests[subscribeRequestId] = (callback: onSuccess, errorCallback: onError, eventCallback: onEvent, topic: topic, queue: queue)
    }

    internal func unregister(_ registration: NSNumber,
                              onSuccess: @escaping UnregisterCallback,
                              onError: @escaping ErrorUnregsiterCallback, queue: DispatchQueue) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.subscribe][ERROR] - You try to unregister \(registration) but you're session id is nil")
            return
        }

        let requestId = self.generateRequestId()
        // Tell router to unsubscribe me from some subscription
        self.sendMessage(UnregisterSwampMessage(requestId: requestId, registration: registration))
        // Store request ID to handle result
        self.unregisterRequests[requestId] = (registration, onSuccess, onError, queue: queue)
    }

    /**
     Unsubscribe is internal because only a Subscription object can call this.
     this function send an unsubscribe request to the server.
     For unsubscribe to a topic, you must specify the subscribe id, a success and an error callback.

     - Parameter subscription: the subscribe id
     - Parameter onSuccess: it's the function called if the unsubscribe request succeed
        the type of this function is the typealias UnsubscribeCallback, here is the complete signature :
        () -> Void
     - Parameter onError: it's the function called if the unsubscribe request failed
        the type of this function is the typealias ErrorUnsubscribeCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     */
    internal func unsubscribe(_ subscription: NSNumber,
                              using queue: DispatchQueue = .main,
                              onSuccess: @escaping UnsubscribeCallback,
                              onError: @escaping ErrorUnsubscribeCallback) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.unsubscribe][ERROR] - You try to unsubscribe \(subscription) but you're session id is nil")
            return
        }

        let unsubscribeRequestId = self.generateRequestId()
        // Tell router to unsubscribe me from some subscription
        self.sendMessage(UnsubscribeSwampMessage(requestId: unsubscribeRequestId, subscription: subscription))
        // Store request ID to handle result
        self.unsubscribeRequests[unsubscribeRequestId] = (subscription, onSuccess, onError, queue: queue)
    }

    // MARK: Publisher role

    /**
     Publish send an event (with args) on a topic.
     This publish is without acknowledging, and doesn't have callback params, if you want a success/error callback,
     an other publish function exist with acknowledging

     - Parameter topic: A String describing the topic name
     - Parameter options: An optional [String: Any] dict containing all options about the publish
     - Parameter args: An optional list of all arguments you want to communicate with this publish
     - Parameter kwargs: An optional dict of all arguments you want to communicate with this publish indexing by key
     */
    open func publish(_ topic: String,
                      options: [String: Any] = [:],
                      args: [Any]? = nil,
                      kwargs: [String: Any]? = nil,
                      using queue: DispatchQueue = .main) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.publish][ERROR] - You try to publish \(topic) but you're session id is nil")
            return
        }
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishSwampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // We don't need to store the request, because it's unacknowledged anyway
    }

    /**
     Publish send an event (with args) on a topic.
     This publish is with acknowledging, you must specify success and error callbacks, if you don't care about the
     publish state, you can call the other publish methods without acknowledging

     - Parameter topic: A String describing the topic name
     - Parameter options: An optional [String: Any] dict containing all options about the publish
     - Parameter args: An optional list of all arguments you want to communicate with this publish
     - Parameter kwargs: An optional dict of all arguments you want to communicate with this publish indexing by key
     - Parameter onSuccess: it's the function called if the publish request succeed
        the type of this function is the typealias PublishCallback, here is the complete signature :
        () -> Void
     - Parameter onError: it's the function called if the publish request failed
        the type of this function is the typealias ErrorPublishCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     */
    open func publish(_ topic: String,
                      options: [String: Any] = [:],
                      args: [Any]? = nil,
                      kwargs: [String: Any]? = nil,
                      using queue: DispatchQueue = .main,
                      onSuccess: @escaping PublishCallback,
                      onError: @escaping ErrorPublishCallback) {
        if !self.isConnected() {
            debugPrint("[SwiftWamp.SwampSession.publish][ERROR] - You try to publish \(topic) but you're session id is nil")
            return
        }
        // add acknowledge to options, so we get callbacks
        var options = options
        options["acknowledge"] = true
        // TODO: assert topic is a valid WAMP uri
        let publishRequestId = self.generateRequestId()
        // Tell router to publish the event
        self.sendMessage(PublishSwampMessage(requestId: publishRequestId, options: options, topic: topic, args: args, kwargs: kwargs))
        // Store request ID to handle result
        self.publishRequests[publishRequestId] = (callback: onSuccess, errorCallback: onError, queue: queue)
    }

    // MARK: SwampTransportDelegate

    open func swampTransportDidDisconnect(_ error: NSError?, reason: String?) {
        if let reason = reason {
            self.delegate?.swampSessionEnded(reason)
        } else if let error = error {
            self.delegate?.swampSessionEnded("Unexpected error: \(error.description)")
        } else {
            self.delegate?.swampSessionEnded("Unknown error.")
            if self.autoReconnect {
                self.connect()
            }
        }
    }

    open func swampTransportDidConnectWithSerializer(_ serializer: SwampSerializer) {
        self.serializer = serializer
        // Start session by sending a Hello message!

        var roles = [String: Any]()
        for role in self.supportedRoles {
            // For now basic profile, (demands empty dicts)
            roles[role.rawValue] = [:]
        }

        var details: [String: Any] = [:]

        if let authmethods = self.authmethods {
            details["authmethods"] = authmethods
        }
        if let authid = self.authid {
            details["authid"] = authid
        }
        if let authrole = self.authrole {
            details["authrole"] = authrole
        }
        if let authextra = self.authextra {
            details["authextra"] = authextra
        }

        details["agent"] = self.clientName
        details["roles"] = roles
        self.sendMessage(HelloSwampMessage(realm: self.realm, details: details))
    }

    open func swampTransportReceivedData(_ data: Data) {
        guard let payload = self.serializer?.unpack(data),
              let typeIdentifier = payload[0] as? Int,
              let type = SwampMessageType(rawValue: typeIdentifier) else {
            debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A message is received, but is unknow by SwampMessageType")
            return
        }

        switch type {

        case .welcome:
            let message = WelcomeSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A welcome message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .abort:
            let message = AbortSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - An abort message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .goodbye:
            let message = GoodbyeSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A goodbye message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .error:
            let message = ErrorSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - An error message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .published:
            let message = PublishedSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A published message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .subscribed:
            let message = SubscribedSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A subscribed message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .unsubscribed:
            let message = UnsubscribedSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - An unsubscribed message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .event:
            let message = EventSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - An event message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .result:
            let message = ResultSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A result message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .challenge:
            let message = ChallengeSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A challenge message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .registered:
            let message = RegisteredSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - A registered message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .invocation:
            let message = InvocationSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - An invocation message is received, payload: \(payload)")
            }
            self.handleMessage(message)

        case .unregistered:
            let message = UnregisteredSwampMessage(payload: Array(payload[1 ..< payload.count]))
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData] - An unregistered message is received, payload: \(payload)")
            }
            self.handleMessage(message)

//      Not implemented (TODO : not yet ?)
//        case .hello:
//            let message = HelloSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .publish:
//            let message = PublishSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .subscribe:
//            let message = SubscribeSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .unsubscribe:
//            let message = UnsubscribeSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .register:
//            let message = RegisterSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .unregister:
//            let message = UnregisterSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .yield:
//            let message = YieldSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .call:
//            let message = CallSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

//        case .authenticate:
//            let message = AuthenticateSwampMessage(payload: Array(payload[1 ..< payload.count]))
//            self.handleMessage(message)

        default:
            debugPrint("[SwiftWamp.SwampSession.swampTransportReceivedData][ERROR] - A message is received, but the type isn't supported by SwiftWamp : \(type)")
            return
        }
    }

    fileprivate func handleMessage(_ message: ChallengeSwampMessage) {
        if let authResponse = self.delegate?.swampSessionHandleChallenge(message.authMethod, extra: message.extra) {
            self.sendMessage(AuthenticateSwampMessage(signature: authResponse, extra: [:]))
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - No delegate, abort")
            self.abort()
        }
        // MARK: Session responses
    }

    fileprivate func handleMessage(_ message: WelcomeSwampMessage) {
        self.sessionId = message.sessionId
        let routerRoles = message.details["roles"]! as! [String: [String: Any]]
        self.routerSupportedRoles = routerRoles.keys.map {
            SwampRole(rawValue: $0)!
        }
        self.delegate?.swampSessionConnected(self, sessionId: message.sessionId)
    }


    fileprivate func handleMessage(_ message: GoodbyeSwampMessage) {
        if message.reason != "wamp.error.goodbye_and_out" {
            // Means it's not our initiated goodbye, and we should reply with goodbye
            self.sendMessage(GoodbyeSwampMessage(details: [:], reason: "wamp.error.goodbye_and_out"))
        }
        self.transport.disconnect(message.reason)
    }

    fileprivate func handleMessage(_ message: AbortSwampMessage) {
        self.transport.disconnect(message.reason)
        // MARK: Call role
    }

    fileprivate func handleMessage(_ message: ResultSwampMessage) {
        let requestId = message.requestId
        if let (callback, _, queue) = self.callRequests.removeValue(forKey: requestId) {
            queue.async {
                callback(message.details, message.results, message.kwResults)
            }
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - A Result message is received, but no entry found for key \(requestId) in callRequests")

        }
        // MARK: Subscribe role
    }

    fileprivate func handleMessage(_ message: RegisteredSwampMessage) {
        let requestId = message.requestId
        if let (callback, _, onFire, proc, queue) = self.registerRequests.removeValue(forKey: requestId) {
            // Notify user and delegate him to unsubscribe this subscription
            let registration = Registration(session: self, registration: message.registration, onFire: onFire, proc: proc, queue: queue)
            queue.async {
                callback(registration)
            }
            // Subscription succeeded, we should store event callback for when it's fired
            self.registrations[message.registration] = registration
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - A Registered message is received, but no entry found for key \(requestId) in registerRequests")
        }

    }

    fileprivate func handleMessage(_ message: SubscribedSwampMessage) {
        let requestId = message.requestId
        if let (callback, _, eventCallback, topic, queue) = self.subscribeRequests.removeValue(forKey: requestId) {
            // Notify user and delegate him to unsubscribe this subscription
            let subscription = Subscription(session: self, subscription: message.subscription, onEvent: eventCallback, topic: topic, queue: queue)
            queue.async {
                callback(subscription)
            }
            // Subscription succeeded, we should store event callback for when it's fired
            self.subscriptions[message.subscription] = subscription
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - A Subscribed message is received, but no entry found for key \(requestId) in subscribeRequests")
        }
    }

    fileprivate func handleMessage(_ message: InvocationSwampMessage) {
        if let registration = self.registrations[message.registration] {
            var details = message.details
            if details.count > 0 {
                details["procedure"] = registration.proc
            }
            registration.queue.async {
                let result = registration.onFire(details, message.args, message.kwargs)
                if let kwargs = result as? [String: Any] {
                    self.sendMessage(YieldSwampMessage(requestId: message.requestId, options: [:], args: [], kwargs: kwargs))
                }
                else if let results = result as? [Any] {
                    self.sendMessage(YieldSwampMessage(requestId: message.requestId, options: [:], args: results, kwargs: nil))
                }
                else {
                    self.sendMessage(YieldSwampMessage(requestId: message.requestId, options: [:], args: [result], kwargs: nil))
                }
            }
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Invocation message is received, but no entry found for key \(message.registration) in registrations")
        }
    }

    fileprivate func handleMessage(_ message: EventSwampMessage) {
        if let subscription = self.subscriptions[message.subscription] {
            var details = message.details
            if details.count > 0 {
                details["topic"] = subscription.topic
            }
            subscription.queue.async {
                subscription.eventCallback(details, message.args, message.kwargs)
            }
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Event message is received, but no entry found for key \(message.subscription) in subscriptions")
        }
    }


    fileprivate func handleMessage(_ message: UnregisteredSwampMessage) {
        let requestId = message.requestId
        if let (registrationID, callback, _, queue) = self.unregisterRequests.removeValue(forKey: requestId) {
            if let registration = self.registrations.removeValue(forKey: registrationID) {
                registration.invalidate()
                queue.async {
                    callback()
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Unregistered message is received, but no entry found for key \(registrationID) in registrations")
            }
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Unregistered message is received, but no entry found for key \(requestId) in unregisterRequests")
        }
    }


    fileprivate func handleMessage(_ message: UnsubscribedSwampMessage) {
        let requestId = message.requestId
        if let (subscription, callback, _, queue) = self.unsubscribeRequests.removeValue(forKey: requestId) {
            if let subscription = self.subscriptions.removeValue(forKey: subscription) {
                subscription.invalidate()
                queue.async {
                    callback()
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Unsubscribed message is received, but no entry found for key \(subscription) in subscriptions")
            }
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Unsubscribed message is received, but no entry found for key \(requestId) in unsubscribeRequests")
        }
    }

    fileprivate func handleMessage(_ message: PublishedSwampMessage) {
        let requestId = message.requestId
        if let (callback, _, queue) = self.publishRequests.removeValue(forKey: requestId) {
            queue.async {
                callback()
            }
        } else {
            debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Published message is received, but no entry found for key \(requestId) in publishRequests")
        }
    }


    ////////////////////////////////////////////
    // MARK: Handle error responses
    ////////////////////////////////////////////

    fileprivate func handleMessage(_ message: ErrorSwampMessage) {
        switch message.requestType {
        case SwampMessageType.call:
            if let (_, errorCallback, queue) = self.callRequests.removeValue(forKey: message.requestId) {
                queue.async {
                    errorCallback(message.details, message.error, message.args, message.kwargs)
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Error message with call request type is received, but no entry found for key \(message.requestId) in callRequests")
            }
        case SwampMessageType.subscribe:
            if let (_, errorCallback, _, _, queue) = self.subscribeRequests.removeValue(forKey: message.requestId) {
                queue.async {
                    errorCallback(message.details, message.error)
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Error message with subscribe request type is received, but no entry found for key \(message.requestId) in subscribeRequests")
            }
        case SwampMessageType.unsubscribe:
            if let (_, _, errorCallback, queue) = self.unsubscribeRequests.removeValue(forKey: message.requestId) {
                queue.async {
                    errorCallback(message.details, message.error)
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Error message with unsubscribe request type is received, but no entry found for key \(message.requestId) in unsubscribeRequests")
            }
        case SwampMessageType.publish:
            if let (_, errorCallback, queue) = self.publishRequests.removeValue(forKey: message.requestId) {
                queue.async {
                    errorCallback(message.details, message.error)
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Error message with publish request type is received, but no entry found for key \(message.requestId) in publishRequests")
            }
        case SwampMessageType.register:
            if let (_, errorCallback, _, _, queue) = self.registerRequests.removeValue(forKey: message.requestId) {
                queue.async {
                    errorCallback(message.details, message.error)
                }
            } else {
                debugPrint("[SwiftWamp.SwampSession.handleMessage][ERROR] - An Error message with register request type is received, but no entry found for key \(message.requestId) in registerRequests")
            }
        default:
            return
        }
    }

    // MARK: Private methods

    fileprivate func abort() {
        if self.sessionId != nil {
            return
        }
        self.sendMessage(AbortSwampMessage(details: [:], reason: "wamp.error.system_shutdown"))
        self.transport.disconnect("No challenge delegate found.")
    }

    fileprivate func sendMessage(_ message: SwampMessage) {
        let marshalledMessage = message.marshal()
        let data = self.serializer!.pack(marshalledMessage as [Any])!
        self.transport.sendData(data)
    }

    fileprivate func generateRequestId() -> Int {
        self.currRequestId += 1
        return self.currRequestId
    }

}
