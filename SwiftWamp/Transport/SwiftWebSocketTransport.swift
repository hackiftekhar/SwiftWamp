//
//  SwiftWebSocketTransport.swift
//  SwiftWamp
//
//  Created by Dany Sousa on 17/02/2017.
//  Copyright © 2017 danysousa. All rights reserved.
//

import Foundation
import SwiftWebSocket

open class SwiftWebSocketTransport: SwampTransport {

    public var enableDebug: Bool = false

    enum WebsocketMode {
        case binary, text
    }

    open var delegate: SwampTransportDelegate?
    private let socket: SwiftWebSocket
    private var wsEndPoint: String
    let mode: WebsocketMode

    fileprivate var disconnectionReason: String?

    public init(wsEndpoint: String, selfSignedSSL: Bool = false, compression: Bool = false) {
        self.mode = .text
        self.wsEndPoint = wsEndpoint
        self.socket = SwiftWebSocket()
        self.socket.allowSelfSignedSSL = selfSignedSSL
        self.socket.compression.on = compression

        self.socket.event.open = self.websocketDidConnect
        self.socket.event.end = self.websocketDidEnd
        self.socket.event.message = self.websocketDidReceiveMessage
    }

    // MARK: Transport

    open func connect() {
        self.socket.open(wsEndPoint, subProtocol: "wamp.2.json")
        if self.enableDebug {
            debugPrint("[SwiftWamp.SwiftWebSocketTransport.connect] - Open socket with endPoint: \(wsEndPoint), compression: \(self.socket.compression.on), allowSelfSignedSSL: \(self.socket.allowSelfSignedSSL)")
        }
    }

    open func disconnect(_ reason: String) {
        self.disconnectionReason = reason
        self.socket.close()

        if self.enableDebug {
            debugPrint("[SwiftWamp.SwiftWebSocketTransport.disconnect] - Close socket to : \(wsEndPoint), for reason: \(reason)")
        }
    }

    open func sendData(_ data: Data) {
        if self.mode == .text {
            let text: String = String(data: data, encoding: String.Encoding.utf8)!
            self.socket.send(text: text)

            if self.enableDebug {
                debugPrint("[SwiftWamp.SwiftWebSocketTransport.sendData] - Send text : \(text)")
            }
        } else {
            self.socket.send(data: data)
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwiftWebSocketTransport.sendData] - Send data : \(data)")
            }
        }
    }

    // MARK: WebSocket.event

    open func websocketDidConnect() {
        // TODO: Check which serializer is supported by the server, and choose self.mode and serializer
        delegate?.swampTransportDidConnectWithSerializer(JSONSwampSerializer())
        if self.enableDebug {
            debugPrint("[SwiftWamp.SwiftWebSocketTransport.websocketDidConnect] - WebSocket connected")
        }
    }

    open func websocketDidEnd(_ code : Int, _ reason : String, _ wasClean : Bool, _ error : Error?) {
        delegate?.swampTransportDidDisconnect(error as NSError?, reason: self.disconnectionReason)
        if self.enableDebug {
            debugPrint("[SwiftWamp.SwiftWebSocketTransport.websocketDidDisconnect] - WebSocket closed, code: \(code), reason: \(reason), wasClean: \(wasClean)")
        }
    }

    open func websocketDidReceiveMessage(message: Any) {
        guard let text = message as? String else {
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwiftWebSocketTransport.websocketDidReceiveMessage][ERROR] - WebSocket received a message, but it can't be cast in String : \(message)")
            }
            return
        }
        if let data = text.data(using: String.Encoding.utf8) {
            if self.enableDebug {
                debugPrint("[SwiftWamp.SwiftWebSocketTransport.websocketDidReceiveMessage] - WebSocket received a message : \(text)")
            }
            delegate?.swampTransportReceivedData(data)
        }
        else if self.enableDebug {
            debugPrint("[SwiftWamp.SwiftWebSocketTransport.websocketDidReceiveMessage][ERROR] - WebSocket received a message, but it can't be contained in data : \(text)")
        }
    }
}
