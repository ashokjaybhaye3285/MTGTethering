//
//  AccessPoint.swift
//  MTGTethering
//
//  Created by Stanislav Stasiuk on 3/24/17.
//
//

import Foundation

@objc enum AccessPointStatus: Int {
    case configured = 0
    case failedToConfig = 1
    case unknown = 10
}

class AccessPoint: Equatable {
    private(set) var parameters: AccessPointParameters
    var devicesConnected: Int
    var status: AccessPointStatus
    
    init(parameters: AccessPointParameters, devicesConnected: Int = 0, status: AccessPointStatus = .unknown) {
        self.parameters = parameters
        self.devicesConnected = devicesConnected
        self.status = status
    }
    
    func updateParameters(_ parameters: AccessPointParameters) {
        self.parameters = parameters
    }
}

func ==(lhs: AccessPoint, rhs: AccessPoint) -> Bool {
    return lhs.parameters == rhs.parameters && lhs.devicesConnected == rhs.devicesConnected && lhs.status == rhs.status
}

struct AccessPointParameters: Equatable {
    let ssid: String
    let securityType: SecurityType
    let broadcasting: Bool
    let password: String
    let channel: String
    
    init(ssid: String = "", password:String = "", securityType: SecurityType = .Open, channel: String = "", broadcasting: Bool = true) {
        self.ssid = ssid
        self.password = password
        self.securityType = securityType
        self.channel = channel
        self.broadcasting = broadcasting
    }
}

func ==(lhs: AccessPointParameters, rhs: AccessPointParameters) -> Bool {
    return lhs.ssid == rhs.ssid && lhs.password == rhs.password && lhs.securityType == rhs.securityType && lhs.channel == rhs.channel && lhs.broadcasting == rhs.broadcasting
}

class NetworkChannel {
    let name: String
    let frequency: String
    
    init (name: String, frequency: String = "") {
        self.name = name
        self.frequency = frequency
    }
}
