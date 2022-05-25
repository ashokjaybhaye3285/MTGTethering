//
//  CommunicationsManagerTests.swift
//  CommunicationsManagerTests
//
//  Created by Moody Jeff on 2/29/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import XCTest
@testable import YukonSim

import CoreBluetooth

class CommunicationsManagerTests: XCTestCase {
    // delimiter at the end of the message
    private let EOM_DELIMITER = "\u{1C}"
    // delimiter for sets of fields
    private let RECORD_DELIMITER = "\u{1E}"
    // delimiter for each field in the message
    private let UNIT_DELIMITER = "\u{1F}"

    let characteristicsManager: CharacteristicsManager = CharacteristicsManager()
    let logTextView = UITextView()
    var communicationsManager: CommunicationsManager?
    
    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.
        communicationsManager = CommunicationsManager(delegate: MockDelegate(), characteristicsManager: characteristicsManager, logTextView: logTextView)
        communicationsManager?.initialize()
    }
    
    func testReceiveMessage() {
        let mode = "1" // set the client and access point states
        let clientState = "1"
        let accessPointState = "0"
        let message: String = String(MessageType.TetheringStateUpdate.rawValue) + RECORD_DELIMITER + mode + RECORD_DELIMITER + clientState + RECORD_DELIMITER + accessPointState + EOM_DELIMITER
        let data: NSData? = CommunicationsManager.convertTextToData(message)
        communicationsManager?.processWriteRequest(CHARACTERISTIC_UUID_RxData, data: data)
    }
}

class MockDelegate : CommunicationsManagerDelegate {
    func connectedWifiNetworkConnectionChanged(wiFiNetwork: WiFiNetwork) {
    }
}
