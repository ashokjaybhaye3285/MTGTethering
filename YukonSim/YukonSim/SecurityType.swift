//
//  SecurityType.swift
//  YukonSim
//
//  Created by Schumacher Clay on 4/11/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import Foundation

enum SecurityType:String {
    case Open = "0"
    case WEP = "1"
    case WPAPersonal = "2"
    case WPAEnterprise = "3"
    case WPA2Personal = "4"
    case WPA2Enterprise = "5"
    
    static func getTextForSecurityType(securityType: SecurityType) -> String {
        switch securityType {
        case Open:
            return "Open"
        case WPA2Personal:
            return "WPA2"
        default:
            return "undefined"
        }
    }
}