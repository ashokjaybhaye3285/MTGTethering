//
//  ConnectionStatus.swift
//  YukonSim
//
//  Created by Schumacher Clay on 4/11/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import Foundation

enum ConnectionStatus: String {
    case NotConnected = "0"
    case Connected = "1"
    case Disconnected = "2"
    case Save = "3"
    case Saved = "4"
    case Delete = "5"
    case DeletedSuccessfully = "6"
    case ErrorPasswordInvalid = "7"
    case ErrorConnectionError = "8"
    case Tethered = "9"
    case TetheredNoInternet = "10"
    case FailedToSaveNetwork = "11"
}