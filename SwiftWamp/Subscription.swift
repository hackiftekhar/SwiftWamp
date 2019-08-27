//
// Created by Dany Sousa on 28/10/2016.
// Copyright (c) 2016 danysousa. All rights reserved.
//

import Foundation

/**
 Subscription is a class describing a subscribe, you can find the subscribe id, the session, the status and the
 event callback.

 This class is used for SubscribeCallback param and cannot instantiate outside the SwiftWamp target
 */
open class Subscription {
    fileprivate let session: SwampSession
    internal let subscription: NSNumber
    internal let queue: DispatchQueue
    internal var eventCallback: EventCallback
    fileprivate var isActive: Bool = true
    public let topic: String

    internal init(session: SwampSession, subscription: NSNumber, onEvent: @escaping EventCallback, topic: String, queue: DispatchQueue) {
        self.session = session
        self.subscription = subscription
        self.eventCallback = onEvent
        self.topic = topic
        self.queue = queue
    }

    internal func invalidate() {
        self.isActive = false
    }

    /**
     Cancel is the method for unsubscribe this subscription. This function is an alias of SwampSession.unsubscribe

     - Parameter onSuccess: it's the function called if the unsubscribe request succeeded
        the type of this function is the typealias UnsubscribeCallback, here is the complete signature :
        () -> Void

     - Parameter onError: it's the function called if the unsubscribe request failed
        the type of this function is the typealias ErrorUnsubscribeCallback, here is the complete signature :
        (_ details: [String: Any], _ error: String) -> Void
     */
    open func cancel(_ onSuccess: @escaping UnsubscribeCallback, onError: @escaping ErrorUnsubscribeCallback) {
        if !self.isActive {
            onError([:], "Subscription already inactive.")
        }
        self.session.unsubscribe(self.subscription, onSuccess: onSuccess, onError: onError)
    }

    open func changeEventCallback(callback: @escaping EventCallback) {
        self.eventCallback = callback
    }
}
