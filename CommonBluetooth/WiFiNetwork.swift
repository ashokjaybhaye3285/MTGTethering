//
//  WiFiNetwork.swift
//  MTGTethering
//
//  Created by Schumacher Clay on 4/11/16.
//
//

import Foundation

class WiFiNetwork {
    static let SIGNAL_STRENGTH_NONE: Int = 0
    
    var ssid: String
    var login: String
    var password: String
    var channel: String
    var security: SecurityType
    var signalStrength: Int
    var status: ConnectionStatus
    var connectionChangeInProgress: Bool
    
    convenience init() {
        self.init(ssid: "", login: "", password: "", channel: "", security: .Open, signalStrength: WiFiNetwork.SIGNAL_STRENGTH_NONE, status: .NotConnected)
    }
    
    init(ssid: String, login: String, password: String, channel: String,
        security: SecurityType, signalStrength: Int?, status: ConnectionStatus) {
        self.ssid = ssid
        self.login = login
        self.password = password
        self.channel = channel
        self.security = security
        if signalStrength != nil {
            self.signalStrength = signalStrength!
        } else {
            self.signalStrength = WiFiNetwork.SIGNAL_STRENGTH_NONE
        }
        self.status = status
        self.connectionChangeInProgress = false
    }
    
    convenience init(network: WiFiNetwork) {
        self.init(ssid: network.ssid, login: network.login, password: network.password, channel: network.channel, security: network.security, signalStrength: network.signalStrength, status: network.status)
    }
    
    func createDebugString() -> String {
        return "SSID=\(ssid), Login=\(login), Password=\(password), Channel=\(channel), Security=\(security), SignalStrength=\(signalStrength), Status=\(status)"
    }
    
    func isConnected() -> Bool {
        switch (self.status) {
        case .Connected:
            return true
        case .Tethered:
            return true
        case .TetheredNoInternet:
            return true
        default:
            return false
        }
    }
    
    func isSaved() -> Bool {
        return isConnected() || (self.status == .Saved)
    }
    
    func isPasswordRequired() -> Bool {
        return self.security != .Open
    }
    
    func isInRange() -> Bool {
        return signalStrength != WiFiNetwork.SIGNAL_STRENGTH_NONE
    }
}