//
//  Registration.swift
//  SwiftWamp
//
//  Created by Dany Sousa on 12/01/2017.
//  Copyright © 2017 danysousa. All rights reserved.
//

import Foundation

/**
 registration is a class describing a register, you can find the register id, the session, the status and the
 onFire callback.

 This class is used for SubscribeCallback param and cannot instantiate outside the SwiftWamp target
 */
open class Registration {
    fileprivate let session: SwampSession
    internal let registration: NSNumber
    internal let queue: DispatchQueue
    internal var onFire: SwampProc
    fileprivate var isActive: Bool = true
    public let proc: String

    internal init(session: SwampSession, registration: NSNumber, onFire: @escaping SwampProc, proc: String, queue: DispatchQueue) {
        self.session = session
        self.registration = registration
        self.onFire = onFire
        self.proc = proc
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
    open func cancel(_ onSuccess: @escaping UnregisterCallback, onError: @escaping ErrorUnregsiterCallback) {
        if !self.isActive {
            onError([:], "Registration already inactive.")
        }
        self.session.unregister(registration, onSuccess: onSuccess, onError: onError, queue: self.queue)
    }

    open func changeOnFire(callback: @escaping SwampProc) {
        self.onFire = callback
    }
}
