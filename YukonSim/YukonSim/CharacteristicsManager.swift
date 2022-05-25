//
//  CharacteristicsManager.swift
//  YukonSim
//
//  Created by Moody Jeff on 2/23/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import Foundation
import CoreBluetooth

class CharacteristicsManager {
    private var txDataCharacteristic: CBMutableCharacteristic
    private var rxDataCharacteristic: CBMutableCharacteristic
    private var txReadCharacteristic: CBMutableCharacteristic
    private var rxReadCharacteristic: CBMutableCharacteristic
    private var txFormatCharacteristic: CBMutableCharacteristic
    private var rxFormatCharacteristic: CBMutableCharacteristic

    init() {
        self.txDataCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_TxData, properties: [.Notify, .Read], value: nil, permissions: [.Readable])
        self.rxDataCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_RxData, properties: [.Write], value: nil, permissions: [.Writeable])
        self.txReadCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_TxRead, properties: [.Write], value: nil, permissions: [.Writeable])
        self.rxReadCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_RxRead, properties: [.Notify, .Read], value: nil, permissions: [.Readable])
        self.txFormatCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_TxFormat, properties: [.Notify, .Read], value: nil, permissions: [.Readable])
        self.rxFormatCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_RxFormat, properties: [.Write], value: nil, permissions: [.Writeable])
    }

    func getAllCharacteristics() -> [CBCharacteristic] {
        let characteristics:[CBCharacteristic] = [
            self.txDataCharacteristic,
            self.rxDataCharacteristic,
            self.txReadCharacteristic,
            self.rxReadCharacteristic,
            self.txFormatCharacteristic,
            self.rxFormatCharacteristic
        ]
        
        return characteristics
    }
    
    func clearAllCharacteristicValues() {
        self.txDataCharacteristic.value = nil
        self.rxDataCharacteristic.value = nil
        self.txReadCharacteristic.value = nil
        self.rxReadCharacteristic.value = nil
        self.txFormatCharacteristic.value = nil
        self.rxFormatCharacteristic.value = nil
    }
    
    func setEncryptionRequired(encryptionRequried: Bool) {
        var readPermissions: CBAttributePermissions = [.Readable]
        var writePermissions: CBAttributePermissions = [.Writeable]
        
        if encryptionRequried {
            readPermissions.insert(.ReadEncryptionRequired)
            writePermissions.insert(.WriteEncryptionRequired)
        }
        
        self.txDataCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_TxData, properties: [.Notify, .Read], value: nil, permissions: readPermissions)
        self.rxDataCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_RxData, properties: [.Write], value: nil, permissions: writePermissions)
        self.txReadCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_TxRead, properties: [.Write], value: nil, permissions: writePermissions)
        self.rxReadCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_RxRead, properties: [.Notify, .Read], value: nil, permissions: readPermissions)
        self.txFormatCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_TxFormat, properties: [.Notify, .Read], value: nil, permissions: readPermissions)
        self.rxFormatCharacteristic = CBMutableCharacteristic(type: CHARACTERISTIC_UUID_RxFormat, properties: [.Write], value: nil, permissions: writePermissions)
    }
    
    func getTxDataCharacteristic() -> CBMutableCharacteristic? {
        return txDataCharacteristic
    }

    func getRxReadCharacteristic() -> CBMutableCharacteristic? {
        return rxReadCharacteristic
    }

    func convertUuidToCharacteristicName(uuid: CBUUID) -> String {
        var characteristicName: String
        switch (uuid) {
        case CHARACTERISTIC_UUID_TxData:
            characteristicName = "TX Data";
            break
        case CHARACTERISTIC_UUID_RxData:
            characteristicName = "RX Data";
            break
        case CHARACTERISTIC_UUID_TxRead:
            characteristicName = "TX Read"
            break
        case CHARACTERISTIC_UUID_RxRead:
            characteristicName = "RX Read"
            break
        default:
            characteristicName = uuid.UUIDString
        }
        return characteristicName
    }
    
}