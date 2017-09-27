//
//  ViewController.swift
//  ExampleRedBearChat
//
//  Created by Eric Larson on 9/26/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BLEDelegate {
    
    // MARK: VC Properties
    var bleShield = BLE()
    var rssiTimer = Timer()
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var buttonConnect: UIButton!
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var textBox: UITextField!
    @IBOutlet weak var rssiLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        bleShield.delegate = self
    }
    
    func readRSSITimer(timer:Timer){
        bleShield.readRSSI { (number, error) in
            // when RSSI read is complete, display it
            self.rssiLabel.text = String(format: "%.1f",(number?.floatValue)!)
        }
    }

    // MARK: Delegate Methods
    func bleDidUpdateState() {
        
    }
    
    func bleDidConnectToPeripheral() {
        self.spinner.stopAnimating()
        self.buttonConnect.setTitle("Disconnect", for: .normal)
        
        // Schedule to read RSSI every 1 sec.
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                         repeats: true,
                                         block: self.readRSSITimer)

    }
    
    func bleDidDisconnectFromPeripheral() {
        self.buttonConnect.setTitle("Connect", for: .normal)
        rssiTimer.invalidate()
    }
    
    func bleDidReceiveData(data: Data?) {
        // this data could be anything, here we know its an encoded string
        let s = String(bytes: data!, encoding: String.Encoding.utf8)
        labelText.text = s

    }
    
    // MARK: User initiated Functions
    @IBAction func buttonScanForDevices(_ sender: UIButton) {
        
        // disconnect from any peripherals
        var didDisconnect = false
        for peripheral in bleShield.peripherals {
            if(peripheral.state == .connected){
                if(bleShield.disconnectFromPeripheral(peripheral: peripheral)){
                    didDisconnect = true
                }
            }
        }
        // if we disconnected anything, return from button
        if(didDisconnect){
            return
        }
        
        //start search for peripherals with a timeout of 3 seconds
        // this is an asynchronous call and will return before search is complete
        if(bleShield.startScanning(timeout: 3.0)){
            // after three seconds, try to connect to first peripheral
            Timer.scheduledTimer(withTimeInterval: 3.0,
                                 repeats: false,
                                 block: self.connectTimer)
        }
        
        // give connection feedback to the user
        self.spinner.startAnimating()
    }
    
    
    @IBAction func sendDataButton(_ sender: UIButton) {
        
        let s = textBox.text!
        let d = s.data(using: String.Encoding.utf8)!
        bleShield.write(d)
        // if (self.textField.text.length > 16)
    }
    
    func connectTimer(timer:Timer){
        
        if(bleShield.peripherals.count > 0) {
            // connect to the first found peripheral
            bleShield.connectToPeripheral(peripheral: bleShield.peripherals[0])
        }
        else {
            self.spinner.stopAnimating()
        }
    }
    
}








