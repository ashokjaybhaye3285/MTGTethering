//
//  ViewController.swift
//  YukonSim
//
//  Created by Schumacher Clay on 2/15/16.
//  Copyright © 2016 Deere & Company. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    private let defaultMtgIdentifier = "Yukon"
    
    private var characteristicsManager: CharacteristicsManager?
    private var communicationsManager: CommunicationsManager?
    
    @IBOutlet weak var mtgIdTextField: UITextField!
    @IBOutlet weak var advertisingSwitch: UISwitch!
    @IBOutlet weak var encryptionSwitch: UISwitch!
    @IBOutlet weak var tetheredSwitch: UISwitch!
    @IBOutlet weak var internetSwitch: UISwitch!
    @IBOutlet weak var numberOfNetworksTextField: UITextField!
    @IBOutlet weak var txDataTextField: UITextField!
    @IBOutlet weak var logTextView: UITextView!
    
    @IBAction func toggledAdvertise(sender: AnyObject) {
        if self.advertisingSwitch.on {
            self.communicationsManager!.enableAdvertising()
        } else {
            self.communicationsManager!.disableAdvertising()
        }
    }
    
    @IBAction func toggledEncryption(sender: AnyObject) {
        self.communicationsManager!.updateEncryptionSetting(self.encryptionSwitch.on)
    }
    
    @IBAction func toggledTethered(sender: AnyObject) {
        self.communicationsManager!.updateConnectedNetworkSettings(self.tetheredSwitch.on, internetConnected: self.internetSwitch.on)
    }
    
    @IBAction func toggledInternet(sender: AnyObject) {
        self.communicationsManager!.updateConnectedNetworkSettings(self.tetheredSwitch.on, internetConnected: self.internetSwitch.on)
    }
    
    @IBAction func toggledSaveFail(sender: UISwitch) {
        self.communicationsManager?.setSaveFailEnabled(sender.on)
    }
    
    @IBAction func toggleOutgoingComms(sender: UISwitch) {
        self.communicationsManager?.setOutgoingCommunicationsEnabled(sender.on)
    }
    
    @IBAction func mtgIdChanged() {
        setAdvertisingName()
    }
    
    @IBAction func numberOfNetworksChanged(sender: AnyObject) {
        updateNumberOfNetworks()
    }
    
    @IBAction func sendButtonTouched() {
        let txDataMessage = txDataTextField.text!
        self.communicationsManager!.sendTxDataMessage(txDataMessage)
    }

    @IBAction func clearButtonTouched() {
        self.logTextView.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.characteristicsManager = CharacteristicsManager()
        self.communicationsManager = CommunicationsManager(delegate: self, characteristicsManager: characteristicsManager!, logTextView: logTextView!)
        self.communicationsManager!.initialize()
        
        let maxNumberOfNetworksToSend: Int = self.communicationsManager!.getMaxNumberOfNetworksToSend()
        self.numberOfNetworksTextField.text = String(maxNumberOfNetworksToSend)
        
        setAdvertisingName()
        
        self.internetSwitch.setOn(true, animated: true)
        self.toggledInternet(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setAdvertisingName() {
        var mtgIdentifier: String = self.mtgIdTextField.text!
        if mtgIdentifier == "" {
            mtgIdentifier = self.defaultMtgIdentifier
        }
        self.communicationsManager!.setAdvertisingName(mtgIdentifier)
    }
    
    private func updateNumberOfNetworks() {
        let numberOfNetworksText: String = self.numberOfNetworksTextField.text!
        if (!numberOfNetworksText.isEmpty) {
            self.communicationsManager!.setNumberOfNetworksToSend(Int(numberOfNetworksText)!)
        }
    }
}

extension ViewController: CommunicationsManagerDelegate {
    func connectedWifiNetworkConnectionChanged(wiFiNetwork: WiFiNetwork) {
        self.tetheredSwitch.on = wiFiNetwork.isConnected()
    }
}
