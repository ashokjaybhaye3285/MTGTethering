//
//  MessageTypes.swift
//  YukonSim
//
//  Created by Moody Jeff on 2/22/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import Foundation

enum MessageType: Int {
    case status = 0
    case requestForScannedList = 1
    case scannedListResponse = 2
    case connectToHotspot = 3
    case setPrioritiesList = 4
    case clear = 5
    case disconnect = 6
    case capability = 7
    case tetheringStateUpdate = 8
    case tetheringStateUpdateResponse = 9
    case requestForCapabilities = 10
    case requestForStatus = 11
    case requestForAccessPointStatus = 12
    case accessPointStatusResponse = 13
    case setAccessPoint = 15
    case setAccessPointResponse = 18
    case requestForAccessPointChannelsList = 19
    case accessPointChannelsListResponse = 20
}

enum WiFiScannedListRequestType: Int {
    case all = 0
    case inRange = 1
    case stored = 2
}

enum TetheringStateMode: Int {
    case request = 0
    case set = 1
}

enum TetheringState: Int {
    case disabled = 0
    case enabled = 1
    case ignore = 3
}

enum AccessPointState: Int {
    case disabled = 0
    case enabled = 1
    case ignore = 3
}

