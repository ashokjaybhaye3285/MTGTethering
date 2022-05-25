//
//  CommunicationsManager.swift
//  YukonSim
//
//  Created by Moody Jeff on 2/22/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit


protocol CommunicationsManagerDelegate {
    func connectedWifiNetworkConnectionChanged(wiFiNetwork: WiFiNetwork)
}

class WiFiNetworkEx : WiFiNetwork {
    private var broadcastSsid: Bool
    
    init(ssid: String, login: String, password: String, channel: String, security: SecurityType, signalStrength: Int, status: ConnectionStatus, broadcastSsid: Bool) {
        self.broadcastSsid = broadcastSsid
        super.init(ssid: ssid, login: login, password: password, channel: channel, security: security, signalStrength: signalStrength, status: status)
    }
}

/**
 * This class is used to handle Bluetooth LE communications to and from an MTG.
 *
 * Documentation in this class uses the following abbreviations:
 * [RD] Record delimiter
 * [UD] Unit delimiter
 
 * Format of the WiFi network info in the messages is defined as:
 * SSID[UD]Login[UD]Password[UD]Channel[UD]Security[UD]SignalStrength[UD]Status
 *
 * This will be abbreviated as:
 * <NETWORK>
 */
class CommunicationsManager : NSObject {
    
    private class Message {
        let characteristic: CBMutableCharacteristic
        let messageText: String
        
        init(characteristic: CBMutableCharacteristic, messageText: String) {
            self.characteristic = characteristic
            self.messageText = messageText
        }
    }
    
    private enum LogLevel: Int {
        case Error
        case Warning
        case Normal
        case Debug
    }
    
    private let APP_UUID = CBUUID(string: "7D7286AA-A85D-4F41-8545-3842A4322167")
    private let TETHERING_STATE_UPDATE_MESSAGE_MODE_REQUEST = "0"
    private let TETHERING_STATE_UPDATE_MESSAGE_MODE_SET_STATES = "1"
    private static let TETHERING_STATE_DISABLED = "0"
    private static let TETHERING_STATE_ENABLED = "1"
    
    private let MAX_NUM_CHARS_TO_SEND:Int = 20
    private let STATUS_UPDATE_SECONDS = 3.0
    
    private let logLevel: LogLevel = .Normal
    
    private var scannedNetworks: [WiFiNetworkEx] = [
        WiFiNetworkEx(ssid: "John's Verizon MiFi", login: "", password: "jpassword", channel: "2", security: .WPA2Personal,
            signalStrength: -70, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "McCullough Home", login: "", password: "", channel: "1", security: .Open,
            signalStrength: -40, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "EODINET", login: "", password: "epassword", channel: "4", security: .WPA2Personal,
            signalStrength: -90, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "Workshop's Wi-Fi", login: "", password: "", channel: "5", security: .WPAEnterprise,
            signalStrength: -100, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "3apt1s", login: "", password: "3password", channel: "3", security: .WPA2Personal,
            signalStrength: -55, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "WEP", login: "", password: "", channel: "6", security: .WEP,
            signalStrength: -60, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "WPA", login: "", password: "", channel: "7", security: .WPAPersonal,
            signalStrength: -50, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "WPA2 Enterprise", login: "", password: "", channel: "7", security: .WPA2Enterprise,
            signalStrength: -80, status: .NotConnected, broadcastSsid: true),
        WiFiNetworkEx(ssid: "hidden open", login: "", password: "", channel: "7", security: .Open,
            signalStrength: -75, status: .NotConnected, broadcastSsid: false),
        WiFiNetworkEx(ssid: "hidden wpa", login: "", password: "hpassword", channel: "7", security: .WPAPersonal,
            signalStrength: -45, status: .NotConnected, broadcastSsid: false),
        WiFiNetworkEx(ssid: "hidden wpa2", login: "", password: "hpassword", channel: "7", security: .WPA2Personal,
            signalStrength: -85, status: .NotConnected, broadcastSsid: false),
        ]
    
    private var savedNetworks: [WiFiNetwork] = [
        WiFiNetwork(ssid: "John's Verizon MiFi", login: "", password: "jpassword", channel: "2", security: .WPA2Personal,
            signalStrength: WiFiNetwork.SIGNAL_STRENGTH_NONE, status: .Saved),
        WiFiNetwork(ssid: "McCullough Home", login: "", password: "", channel: "1", security: .Open,
            signalStrength: WiFiNetwork.SIGNAL_STRENGTH_NONE, status: .Saved),
        WiFiNetwork(ssid: "Farmville", login: "",  password: "fpassword", channel: "3", security: .WPA2Personal,
            signalStrength: WiFiNetwork.SIGNAL_STRENGTH_NONE, status: .Saved),
        WiFiNetwork(ssid: "EODINET", login: "", password: "wrong password", channel: "4", security: .WPA2Personal,
            signalStrength: WiFiNetwork.SIGNAL_STRENGTH_NONE, status: .Saved),
        ]
    private var savedNetworksMutex: NSObject = NSObject()
    
    private var maxNumberOfNetworksToSend: Int = 15
    private var tetheringClientState: String = CommunicationsManager.TETHERING_STATE_ENABLED
    private var tetheringAccessPointState: String = CommunicationsManager.TETHERING_STATE_DISABLED
    
    private let delegate: CommunicationsManagerDelegate
    private let characteristicsManager: CharacteristicsManager
    private let logTextView: UITextView
    
    private var peripheralManager: CBPeripheralManager?
    private var service: CBMutableService?
    
    // message received via the RX Data characteristic
    private var rxMessage: String = ""
    
    private var outgoingMessageQueue: [Message] = []
    private var outgoingQueueMutex: NSObject = NSObject()
    private var txDataMessageQueue: [String] = []
    private var txDataQueueMutex: NSObject = NSObject()
    private var readyToSend: Bool = true
    
    private var advertisingEnabled: Bool = true
    private var advertisingName: String = ""
    private var connectionShouldHaveInternet: Bool = false
    private var saveFailEnabled: Bool = false
    private var outgoingCommunicationsEnabled: Bool = true
    
    private var bluetoothOn: Bool = false
    private var centralIsConnected: Bool = false
    
    private var statusUpdateTimer: NSTimer = NSTimer()
    
    init(delegate: CommunicationsManagerDelegate, characteristicsManager: CharacteristicsManager, logTextView: UITextView) {
        self.delegate = delegate
        self.characteristicsManager = characteristicsManager
        self.logTextView = logTextView
    }
    
    private static func convertDataToText(data: NSData?) -> String {
        var text: String
        if data == nil {
            text = "nil"
        } else {
            text = (NSString(data: (data!.copy() as! NSData) as NSData, encoding: NSUTF8StringEncoding) as! String)
        }
        return text
    }
    
    static func convertTextToData(text: String) -> NSData? {
        return text.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    /**
     * Create the peripheral manager. This must be called prior to starting.
     */
    func initialize() {
        let options: [String : AnyObject] = [CBPeripheralManagerOptionShowPowerAlertKey : true,
                                             CBPeripheralManagerOptionRestoreIdentifierKey : APP_UUID]
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: options)
    }
    
    func setAdvertisingName(advertisingName: String) {
        if advertisingName != self.advertisingName {
            self.advertisingName = advertisingName
            stopAdvertising()
            startAdvertising()
        }
    }
    
    func enableAdvertising() {
        self.advertisingEnabled = true
        startAdvertising()
    }
    
    func disableAdvertising() {
        self.advertisingEnabled = false
        stopAdvertising()
    }
    
    private func log(logStatement: String, logLevel: LogLevel = .Normal) {
        var formattedLogStatement: String = ""
        if logLevel != .Normal {
            formattedLogStatement = "|\(logLevel.rawValue)| "
        }
        
        formattedLogStatement += "\(logStatement)"
        print(formattedLogStatement)
        
        if logLevel.rawValue <= self.logLevel.rawValue {
            let logStatementWithCarriageReturn = "\(formattedLogStatement)\r"
            self.logTextView.text.appendContentsOf(logStatementWithCarriageReturn)
        }
    }
    
    private func logNetwork(network: WiFiNetwork) {
        log("   Network: ssid=\(network.ssid), status=\(network.status), connected=\(network.isConnected())")
    }
    
    private func startService() {
        log("Starting service", logLevel: .Debug)
        self.service = CBMutableService(type: SERVICE_UUID, primary: true)
        self.service!.characteristics = characteristicsManager.getAllCharacteristics()
        self.peripheralManager?.addService(service!)
        startAdvertising()
    }
    
    private func stopService() {
        log("Stopping service", logLevel: .Debug)
        stopAdvertising()
        onCentralDisconnected()
        self.service = nil
        self.peripheralManager?.removeAllServices()
    }
    
    private func onCentralConnected() {
        if !self.centralIsConnected {
            log("Central is connected.")
            self.centralIsConnected = true
            stopAdvertising()
        }
    }
    
    private func onCentralDisconnected() {
        if self.centralIsConnected {
            log("Central is disconnected.")
            self.centralIsConnected = false
            stopStatusUpdateTimer()
            clearOutgoingMessageQueue()
            clearTxDataQueue()
            self.characteristicsManager.clearAllCharacteristicValues()
            stopService()
            startService()
        }
    }
    
    private func startAdvertising() {
        if self.advertisingEnabled && self.bluetoothOn && !self.centralIsConnected && !self.advertisingName.characters.isEmpty {
            log("Advertising as: \(self.advertisingName)")
            self.peripheralManager?.startAdvertising([
                CBAdvertisementDataLocalNameKey : self.advertisingName,
                CBAdvertisementDataServiceUUIDsKey : [SERVICE_UUID]
                ])
        }
    }
    
    private func stopAdvertising() {
        if self.peripheralManager?.isAdvertising == true {
            log("Stopping advertising")
            self.peripheralManager?.stopAdvertising()
        }
    }
    
    func updateEncryptionSetting(encryptionRequired: Bool) {
        stopService()
        self.characteristicsManager.setEncryptionRequired(encryptionRequired)
        startService()
    }
    
    func updateConnectedNetworkSettings(tethered: Bool, internetConnected: Bool) {
        self.connectionShouldHaveInternet = internetConnected
        
        var connectedNetwork: WiFiNetwork? = findConnectedNetwork()
        if tethered && (connectedNetwork == nil) {
            connectedNetwork = findDefaultNetworkToConnect()
        }
        
        if let network = connectedNetwork {
            let status: ConnectionStatus
            if tethered {
                status = getConnectedNetworkStatus()
            } else {
                status = .Disconnected
            }
            setNetworkStatusAndNotifyStatusChanged(network, status: status)
            sendStatusMessageForNetwork(network)
            if !tethered {
                // status is sent as Disconnected, but the cached status should remain not connected
                network.status = .NotConnected
            }
        }
    }
    
    func getMaxNumberOfNetworksToSend() -> Int {
        return maxNumberOfNetworksToSend
    }
    
    func setNumberOfNetworksToSend(numberOfNetworks: Int) {
        if (numberOfNetworks >= 0) {
            self.maxNumberOfNetworksToSend = numberOfNetworks
        }
    }
    
    func setSaveFailEnabled(enabled: Bool) {
        self.saveFailEnabled = enabled
    }
    
    func setOutgoingCommunicationsEnabled(enabled: Bool) {
        self.outgoingCommunicationsEnabled = enabled
        if enabled {
            sendNextTxDataMessage()
        }
    }
    
    private func findDefaultNetworkToConnect() -> WiFiNetwork? {
        var network: WiFiNetwork? = findNetworkForAutoConnect()
        if network == nil {
            let networksOrderedBySignalStrength = self.scannedNetworks.sort(sortBySignalStrength)
            network = networksOrderedBySignalStrength.first
        }
        return network
    }
    
    private func sortBySignalStrength(lhs: WiFiNetwork, rhs: WiFiNetwork) -> Bool {
        return lhs.signalStrength > rhs.signalStrength
    }
    
    private func findNetworkForAutoConnect() -> WiFiNetwork? {
        var network: WiFiNetwork? = nil
        for savedNetwork in self.savedNetworks {
            if let index = self.scannedNetworks.indexOf({$0.isInRange() && ($0.ssid == savedNetwork.ssid) && ($0.security == savedNetwork.security) && ($0.password == savedNetwork.password)}) {
                network = self.scannedNetworks[index]
                break
            }
        }
        return network
    }
    
    private func findConnectedNetwork() -> WiFiNetwork? {
        for network in self.scannedNetworks {
            if network.isConnected() {
                return network
            }
        }
        return nil
    }
    
    private func setNetworkStatusAndNotifyStatusChanged(network: WiFiNetwork, status: ConnectionStatus) {
        if network.status != status {
            network.status = status
            delegate.connectedWifiNetworkConnectionChanged(network)
            
            if network.isConnected() {
                startStatusUpdateTimer()
            } else {
                stopStatusUpdateTimer()
            }
        }
    }
    
    func sendCurrentConnectedNetworkStatus() {
        if let connectedNetwork = findConnectedNetwork() {
            sendStatusMessageForNetwork(connectedNetwork)
        }
    }
    
    private func startStatusUpdateTimer() {
        stopStatusUpdateTimer()
        statusUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(STATUS_UPDATE_SECONDS, target: self, selector: Selector("sendCurrentConnectedNetworkStatus"), userInfo: nil, repeats: true)
    }
    
    private func stopStatusUpdateTimer() {
        statusUpdateTimer.invalidate()
    }
    
    private func getConnectedNetworkStatus() -> ConnectionStatus {
        var status: ConnectionStatus
        if (self.connectionShouldHaveInternet) {
            status = .Tethered
        }
        else {
            status = .TetheredNoInternet
        }
        return status
    }
    
    private func processWriteRequest(request: CBATTRequest) -> Bool {
        return processWriteRequest(request.characteristic.UUID, data: request.value)
    }
    
    public func processWriteRequest(uuid: CBUUID, data: NSData?) -> Bool {
        var result: Bool = true
        let messageText: String = CommunicationsManager.convertDataToText(data)
        
        switch (uuid) {
        case CHARACTERISTIC_UUID_RxData:
            processRxData(messageText)
            break
        case CHARACTERISTIC_UUID_TxRead:
            processTxRead(messageText)
            break
        default:
            result = false
            log("Unhandled request for characteristic: \(self.characteristicsManager.convertUuidToCharacteristicName(uuid))", logLevel: .Error)
        }
        
        return result
    }
    
    private static func convertMessageType(messageTypeString: String) -> MessageType? {
        return MessageType(rawValue: Int(messageTypeString)!)
    }
    
    private static func convertWiFiScannedListRequestType(requestType: String) -> WiFiScannedListRequestType? {
        var wiFiScannedListRequestType: WiFiScannedListRequestType? = nil
        let intType = Int(requestType)
        if intType != nil {
            wiFiScannedListRequestType = WiFiScannedListRequestType(rawValue: intType!)
        }
        return wiFiScannedListRequestType
    }
    
    private func processRxData(messageText: String) {
        log("Received RX Data: {\(formatMessageTextForLogging(messageText))}", logLevel: .Debug)
        
        self.rxMessage.appendContentsOf(messageText)
        
        let rxReadValue = "1"
        sendMessage(self.characteristicsManager.getRxReadCharacteristic(), messageText: rxReadValue)
        
        if messageText.containsString(EOM_DELIMITER) == true {
            handleRxMessage(self.rxMessage)
            self.rxMessage = ""
        }
    }
    
    private func processTxRead(messageText: String) {
        log("Received TX Read: \(messageText)", logLevel: .Debug)
        
        let value: Int = Int(messageText)!
        if (value == 0) {
            log("processTxRead(): Received unexpected TX Read value of 0", logLevel: .Error)
        } else {
            sendNextTxDataMessage()
        }
    }
    
    private func calculateMaxCharactersToSend(messageText: String) -> Int {
        return min(messageText.characters.count, MAX_NUM_CHARS_TO_SEND)
    }
    
    private func sendNextTxDataMessage() {
        if txQueueIsEmpty() {
            log("sendNextTxDataMessage(): returned early because txDataMessageQueue is empty", logLevel: .Debug)
            return
        }
        
        if self.outgoingCommunicationsEnabled {
            let messageText: String = createTxMessageAndUpdateQueue()
            sendMessage(self.characteristicsManager.getTxDataCharacteristic(), messageText: messageText)
        }
    }
    
    private func clearTxDataQueue() {
        synchronized(txDataQueueMutex) {
            self.txDataMessageQueue.removeAll()
        }
    }
    
    private func txQueueIsEmpty() -> Bool {
        return synchronized(txDataQueueMutex) { () -> Bool in
            if self.txDataMessageQueue.isEmpty {
                return true
            }
            return false
        }
    }
    
    private func createTxMessageAndUpdateQueue() -> String {
        return synchronized(txDataQueueMutex) { () -> String in
            var messageText: String = self.txDataMessageQueue.first!
            let maxCharsToSend = self.calculateMaxCharactersToSend(messageText)
            let range = messageText.startIndex..<messageText.startIndex.advancedBy(maxCharsToSend)
            let messageTextPart: String = messageText.substringWithRange(range)
            messageText.removeRange(range)
            
            if messageText.isEmpty {
                self.txDataMessageQueue.removeFirst(1)
            } else {
                self.txDataMessageQueue[0] = messageText
            }
            
            return messageTextPart
        }
    }
    
    private func handleRxMessage(message: String) {
        let messageTypeAndRecords = parseMessageTypeAndRecordsFromMessage(message)
        let messageType: MessageType? = messageTypeAndRecords.messageType
        let records: [String] = messageTypeAndRecords.records
        
        if messageType == nil {
            log("Message type is nil for message: \(message)", logLevel: .Error)
        } else {
            handleRxMessage(message, messageType: messageType!, records: records)
        }
    }
    
    private func handleRxMessage(message: String, messageType: MessageType, records: [String]) {
        let formattedMessage: String = formatMessageTextForLogging(message)
        switch messageType {
        case .RequestForScannedList:
            log("RECEIVED Request for Scanned List")
            log("\(formattedMessage)", logLevel: .Debug)
            handleRequestForScannedList(records)
            break
        case .ConnectToHotspot:
            log("RECEIVED Connect to Hotspot")
            log("\(formattedMessage)", logLevel: .Debug)
            handleConnectionRequest(records)
            break
        case .SetPrioritiesList:
            log("RECEIVED Set Priorities List")
            log("\(formattedMessage)", logLevel: .Debug)
            handleSetPrioritiesList(records)
            break
        case .Clear:
            log("RECEIVED Clear")
            log("\(formattedMessage)", logLevel: .Debug)
            handleClearStoredWiFiNetworks()
            break
        case .Disconnect:
            log("RECEIVED Disconnect")
            log("\(formattedMessage)", logLevel: .Debug)
            handleDisconnectFromCurrentNetworkRequest()
            break
        case .TetheringStateUpdate:
            handleTetheringStateUpdate(records)
            break
        default:
            log("Unhandled message type: \(messageType.rawValue). Message: \(formattedMessage)", logLevel: .Error)
        }
    }
    
    private func encodeNetworkForMessage(network: WiFiNetwork) -> String {
        var signalStrength: String
        if network.signalStrength != WiFiNetwork.SIGNAL_STRENGTH_NONE {
            signalStrength = String(network.signalStrength)
        } else {
            signalStrength = ""
        }
        return network.ssid + UNIT_DELIMITER
            + network.login + UNIT_DELIMITER
            + network.password + UNIT_DELIMITER
            + network.channel + UNIT_DELIMITER
            + network.security.rawValue + UNIT_DELIMITER
            + signalStrength + UNIT_DELIMITER
            + network.status.rawValue
    }
    
    private func parseNetworkFromRecord(record: String) -> WiFiNetwork {
        let units: [String] = parseRecordIntoUnits(record)
        let ssid = units[0]
        let login = units[1]
        let password = units[2]
        let channel = units[3]
        let security = SecurityType(rawValue: units[4])!
        let signalStrength = Int(units[5])!
        let status = ConnectionStatus(rawValue: units[6])!
        let network: WiFiNetwork = WiFiNetwork(ssid: ssid, login: login, password: password, channel: channel, security: security, signalStrength: signalStrength, status: status)
        return network
    }
    
    private func handleRequestForScannedList(records: [String]) {
        var requestType: WiFiScannedListRequestType = WiFiScannedListRequestType.All
        if !records.isEmpty {
            let parsedType = CommunicationsManager.convertWiFiScannedListRequestType(records.first!)
            if parsedType == nil {
                log("Invalid WiFi scanned list request type: \(records.first)", logLevel: .Error)
            } else {
                requestType = parsedType!
            }
        }
        
        var networksToSend: [WiFiNetwork]
        switch requestType {
        case .InRange:
            networksToSend = findInRangeNetworks()
            log("SENDING in range networks")
            break
        case .Stored:
            networksToSend = findStoredNetworks()
            log("SENDING stored networks")
            break
        default:
            networksToSend = findInRangeAndStoredNetworks()
            log("SENDING in range and stored networks")
            break
        }
        
        sendStatusMessageForNetworks(networksToSend, messageType: MessageType.ScannedListResponse)
    }
    
    private func findInRangeNetworks() -> [WiFiNetwork] {
        var networks: [WiFiNetwork] = []
        for network in self.scannedNetworks {
            if network.isInRange() && network.broadcastSsid {
                networks.append(createNetworkWithNoPassword(network))
            }
        }
        return networks
    }
    
    private func createNetworkWithNoPassword(network: WiFiNetwork) -> WiFiNetwork {
        let networkWithNoPassword = WiFiNetwork(network: network)
        networkWithNoPassword.password = ""
        return networkWithNoPassword
    }
    
    private func findStoredNetworks() -> [WiFiNetwork] {
        return findStoredNetworksIncludingConnectedStatus(includeSignalStrength: false)
    }
    
    private func findInRangeAndStoredNetworks() -> [WiFiNetwork] {
        var networks: [WiFiNetwork] = findScannedInRangeNetworks()
        
        let savedNetworks: [WiFiNetwork] = findStoredNetworksIncludingConnectedStatus(includeSignalStrength: true)
        
        // add stored networks that aren't scanned and in range
        for savedNetwork in savedNetworks {
            if !isNetworkInNetworks(networks, network: savedNetwork) {
                networks.append(savedNetwork)
            }
        }
        
        return networks
    }
    
    private func findStoredNetworksIncludingConnectedStatus(includeSignalStrength includeSignalStrength: Bool) -> [WiFiNetwork] {
        var storedNetworks: [WiFiNetwork] = []
        for var savedNetwork in self.savedNetworks {
            if let index = findNetworkIndex(self.scannedNetworks, network: savedNetwork) {
                let scannedNetwork = self.scannedNetworks[index]
                // copy the network so this doesn't alter the original
                savedNetwork = copySavedNetworkWithStatusOfScannedNetwork(savedNetwork, scannedNetwork: scannedNetwork, copySignalStrength: includeSignalStrength)
            }
            storedNetworks.append(savedNetwork)
        }
        return storedNetworks
    }
    
    private func findScannedInRangeNetworks() -> [WiFiNetwork] {
        var networks: [WiFiNetwork] = []
        for scannedNetwork in findInRangeNetworks() {
            if let index = findNetworkIndex(savedNetworks, network: scannedNetwork) {
                networks.append(copySavedNetworkWithStatusOfScannedNetwork(savedNetworks[index], scannedNetwork: scannedNetwork, copySignalStrength: true))
            } else {
                networks.append(scannedNetwork)
            }
        }
        return networks
    }
    
    private func copySavedNetworkWithStatusOfScannedNetwork(savedNetwork: WiFiNetwork, scannedNetwork: WiFiNetwork, copySignalStrength: Bool) -> WiFiNetwork {
        let savedNetworkCopy = WiFiNetwork(network: savedNetwork)
        if scannedNetwork.isConnected() {
            savedNetworkCopy.status = scannedNetwork.status
        }
        if copySignalStrength {
            savedNetworkCopy.signalStrength = scannedNetwork.signalStrength
        }
        return savedNetworkCopy
    }
    
    private func handleConnectionRequest(records: [String]) {
        let networkToConnect: WiFiNetwork = parseNetworkFromRecord(records[0])
        log("Connecting to network: \(networkToConnect.createDebugString())")
        
        var status: ConnectionStatus = .ErrorConnectionError
        if let index = findNetworkIndex(self.scannedNetworks, network: networkToConnect) {
            let scannedNetwork: WiFiNetwork = self.scannedNetworks[index]
            if scannedNetwork.isInRange() {
                if (scannedNetwork.security == networkToConnect.security) {
                    if !scannedNetwork.isPasswordRequired() || (scannedNetwork.password == networkToConnect.password) {
                        disconnectConnectedNetwork()
                        status = getConnectedNetworkStatus()
                        scannedNetwork.status = status
                        saveNetwork(networkToConnect)
                    } else {
                        status = .ErrorPasswordInvalid
                    }
                }
            }
        }
        
        if (status == .ErrorConnectionError) || (status == .ErrorPasswordInvalid) {
            networkToConnect.status = status
        } else {
            setNetworkStatusAndNotifyStatusChanged(networkToConnect, status: status)
        }
        log("Connection attempt to network: SSID=\(networkToConnect.ssid), Status=\(networkToConnect.status)")
        sendStatusMessageForNetwork(networkToConnect)
    }
    
    private func disconnectConnectedNetwork() {
        if let connectedNetwork = findConnectedNetwork() {
            connectedNetwork.status = .NotConnected
        }
    }
    
    private func saveNetwork(networkToConnect: WiFiNetwork) {
        if let index = findNetworkIndex(self.savedNetworks, network: networkToConnect) {
            let savedNetwork = self.savedNetworks[index]
            savedNetwork.password = networkToConnect.password
        } else {
            let savedNetwork = WiFiNetwork(network: networkToConnect)
            savedNetwork.status = .Saved
            savedNetwork.signalStrength = WiFiNetwork.SIGNAL_STRENGTH_NONE
            self.savedNetworks.append(savedNetwork)
        }
    }
    
    private func handleSetPrioritiesList(records: [String]) {
        var orderedNetworks: [WiFiNetwork] = []
        for record in records {
            let network = parseNetworkFromRecord(record)
            log("     \(network.createDebugString())")
            network.status = (self.saveFailEnabled ? .FailedToSaveNetwork : .Saved)
            orderedNetworks.append(network)
        }
        
        // only store the networks when saving is successful
        if !self.saveFailEnabled {
            let connectedNetwork = findConnectedNetwork()
            var foundConnectedNetworkInOrderedNetworks = false
            self.savedNetworks = orderedNetworks
            log("Saved \(savedNetworks.count) networks:")
            for network in orderedNetworks {
                logNetwork(network)
                if network.ssid == connectedNetwork?.ssid {
                    foundConnectedNetworkInOrderedNetworks = true
                }
            }
            
            // disconnect from connected network if it isn't in the prioritized list of networks
            if let network = connectedNetwork {
                if !foundConnectedNetworkInOrderedNetworks {
                    log("Disconnecting from network: \(network.createDebugString())")
                    setNetworkStatusAndNotifyStatusChanged(network, status: .NotConnected)
                }
            }
        }
        
        log("SENDING response to set prioritized list message")
        sendStatusMessageForNetworks(orderedNetworks, messageType: .ScannedListResponse)
    }
    
    private func isNetworkInNetworks(networks: [WiFiNetwork], network: WiFiNetwork) -> Bool {
        return findNetworkIndex(networks, network: network) != nil
    }
    
    private func findNetworkIndex(networks: [WiFiNetwork], network: WiFiNetwork) -> Int? {
        return networks.indexOf({$0.ssid == network.ssid})
    }
    
    private func handleClearStoredWiFiNetworks() {
        self.savedNetworks.removeAll()
        if let network = findConnectedNetwork() {
            log("Disconnecting from network: \(network.createDebugString())")
            setNetworkStatusAndNotifyStatusChanged(network, status: .NotConnected)
        }
    }
    
    private func handleDisconnectFromCurrentNetworkRequest() {
        for network in self.scannedNetworks {
            if network.isConnected() {
                log("Disconnecting from network: \(network.createDebugString())")
                let networkForResponse = WiFiNetwork(network: network)
                networkForResponse.status = .Disconnected
                sendStatusMessageForNetwork(networkForResponse)
                setNetworkStatusAndNotifyStatusChanged(network, status: .NotConnected)
                break
            }
        }
    }
    
    private func handleTetheringStateUpdate(records: [String]) {
        if records.count != 3 {
            log("Malformed tethering state update message.", logLevel: .Error)
        } else {
            let mode = records[0]
            
            switch (mode) {
            case TETHERING_STATE_UPDATE_MESSAGE_MODE_REQUEST:
                log("RECEIVED tethering state request")
                break;
            case TETHERING_STATE_UPDATE_MESSAGE_MODE_SET_STATES:
                self.tetheringClientState = records[1]
                self.tetheringAccessPointState = records[2]
                log("RECEIVED setting tethering state. Client State=\(tetheringClientState), Access Point State=\(tetheringAccessPointState)")
                break;
            default:
                log("Unhandled tethering mode: \(mode)", logLevel: .Error)
            }
            
            sendTetheringStateResponseMessage()
        }
    }
    
    func sendTxDataMessage(messageText: String) {
        synchronized(txDataQueueMutex) {
            let messageTextWithEom = messageText + EOM_DELIMITER
            self.txDataMessageQueue.append(messageTextWithEom)
            self.log("Added to TX Data Queue: \(self.formatMessageTextForLogging(messageTextWithEom))", logLevel: .Debug)
        }
        sendNextTxDataMessage()
    }
    
    private func sendStatusMessageForNetwork(network: WiFiNetwork) {
        let networks = [network]
        sendStatusMessageForNetworks(networks, messageType: MessageType.Status)
    }
    
    private func sendStatusMessageForNetworks(networks: [WiFiNetwork], messageType: MessageType) {
        var networksToSend = networks
        if networks.count > maxNumberOfNetworksToSend {
            if maxNumberOfNetworksToSend == 0 {
                networksToSend = []
            } else {
                let endIndex = maxNumberOfNetworksToSend - 1
                networksToSend = Array(networks[0...endIndex])
            }
        }
        
        // Format:
        // MessageType[RD]<NETWORK 1>
        //            [RD]<NETWORK 2>
        //            ...
        //            [RD]<NETWORK n>
        var messageText:String = String(messageType.rawValue) + RECORD_DELIMITER
        for i in 0..<networksToSend.count {
            let network = networks[i]
            logNetwork(network)
            messageText.appendContentsOf(encodeNetworkForMessage(network))
            if i < networks.count - 1 {
                messageText.appendContentsOf(RECORD_DELIMITER)
            }
        }
        sendTxDataMessage(messageText)
    }
    
    private func sendTetheringStateResponseMessage() {
        log("SENDING tethering state response. Tethering state=\(tetheringClientState)")
        // Format:
        // MessageType[RD]<Client State>[RD]AccessPoint State>
        let messageText:String = String(MessageType.TetheringStateUpdateResponse.rawValue) + RECORD_DELIMITER + tetheringClientState + RECORD_DELIMITER + tetheringAccessPointState
        sendTxDataMessage(messageText)
    }
    
    private func clearOutgoingMessageQueue() {
        synchronized(outgoingMessageQueue) {
            self.outgoingMessageQueue.removeAll()
        }
    }
    
    private func sendMessage(characteristic: CBMutableCharacteristic?, messageText: String) {
        synchronized(outgoingQueueMutex) {
            let message: Message = Message(characteristic: characteristic!, messageText: messageText)
            self.outgoingMessageQueue.append(message)
            self.log("Added to Outgoing Message Queue: \(self.formatMessageTextForLogging(messageText))", logLevel: .Debug)
        }
        send()
    }
    
    private func send() {
        synchronized(outgoingQueueMutex) {
            while self.readyToSend && !self.outgoingMessageQueue.isEmpty {
                let message: Message = self.outgoingMessageQueue[0]
                let characteristicName = self.characteristicsManager.convertUuidToCharacteristicName(message.characteristic.UUID)
                if self.updateCharacteristicValue(message.characteristic, messageText: message.messageText) {
                    self.outgoingMessageQueue.removeFirst()
                    self.log("Sent \(characteristicName): {\(self.formatMessageTextForLogging(message.messageText))}", logLevel: .Debug)
                } else {
                    self.readyToSend = false
                    self.log("Updating characteristic failed. Characteristic: \(characteristicName), message=\(message.messageText)", logLevel: .Debug)
                }
            }
        }
    }
    
    private func formatMessageTextForLogging(messageText: String) -> String {
        var formattedMessageText = messageText.stringByReplacingOccurrencesOfString(RECORD_DELIMITER, withString: "[RECORD]")
        formattedMessageText = formattedMessageText.stringByReplacingOccurrencesOfString(UNIT_DELIMITER, withString: "[UNIT]")
        return formattedMessageText
    }
    
    private func updateCharacteristicValue(characteristic: CBMutableCharacteristic, messageText: String) -> Bool {
        let data: NSData? = CommunicationsManager.convertTextToData(messageText)
        return (self.peripheralManager!.updateValue(
            data!,
            forCharacteristic: characteristic,
            onSubscribedCentrals: nil
            ))
    }
    
    private func removeEomFromMessage(messageText: String) -> (result: Bool, messageTextWithoutEOM: String) {
        var success: Bool
        var messageTextWithoutEOM = messageText
        let tokens: [String] = messageTextWithoutEOM.componentsSeparatedByString(EOM_DELIMITER)
        if tokens.isEmpty {
            success = false
            log("removeEomFromMessage(): no tokens found in: \(messageTextWithoutEOM)", logLevel: .Error)
        } else {
            success = true
            messageTextWithoutEOM = tokens[0]
        }
        
        return (success, messageTextWithoutEOM)
    }
    
    private func parseMessageTypeAndRecordsFromMessage(messageText: String) -> (messageType: MessageType?, records: [String]) {
        var messageType: MessageType? = nil
        var records: [String] = []
        
        let messageTextWithoutEomResult = removeEomFromMessage(messageText)
        if messageTextWithoutEomResult.result {
            var messageTypeAndRecords = messageTextWithoutEomResult.messageTextWithoutEOM.componentsSeparatedByString(RECORD_DELIMITER)
            let messageTypeToken = messageTypeAndRecords.first
            messageType = CommunicationsManager.convertMessageType(messageTypeToken!)
            messageTypeAndRecords.removeFirst()
            records = messageTypeAndRecords
        }
        
        return (messageType, records)
    }
    
    private func parseRecordIntoUnits(record: String) -> [String] {
        let units = record.componentsSeparatedByString(UNIT_DELIMITER)
        return units
    }
}

extension CommunicationsManager : CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if (peripheral.state == .PoweredOff) {
            self.bluetoothOn = false
            stopService()
        } else if (peripheral.state == .PoweredOn) {
            self.bluetoothOn = true
            startService()
        } else {
            log("Bluetooth peripheral state=\(peripheral.state)", logLevel: .Warning)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        self.peripheralManager?.respondToRequest(request, withResult: CBATTError.Success)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        // only need to respond to the first request
        self.peripheralManager?.respondToRequest(requests[0], withResult: CBATTError.Success)
        
        for request: CBATTRequest in requests {
            processWriteRequest(request)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, willRestoreState dict: [String : AnyObject]) {
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        self.readyToSend = true
        send()
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if error != nil {
            log(error!.debugDescription)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        log("Central subscribed for characteristic: \(characteristicsManager.convertUuidToCharacteristicName(characteristic.UUID))")
        onCentralConnected()
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        log("Central unsubscribed for characteristic: \(characteristicsManager.convertUuidToCharacteristicName(characteristic.UUID))")
        onCentralDisconnected()
    }
}


