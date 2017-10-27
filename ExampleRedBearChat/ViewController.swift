//
//  ViewController.swift
//  ExampleRedBearChat
//
//  Created by Eric Larson on 9/26/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import UIKit

// MARK: CHANGE 2: No longer should this view be a BLE delegate
class ViewController: UIViewController {
    
    // MARK: VC Properties
    // MARK: CHANGE 3: No longer have BLE instantiate itself. Instead: Add support for lazy instantiation (like we did in the table view controller)
    lazy var bleShield = (UIApplication.shared.delegate as! AppDelegate).bleShield
    var rssiTimer = Timer()
    
    // -----------------------------------
    
    static let buffersize = 2048
    static let samplingRate = Float(100.0*60)
    static let fftSize = 2048
    let fft = FFTHelper(fftSize: 2048, andWindow: WindowTypeHamming)
    let finder = PeakFinder(frequencyResolution: samplingRate / Float(fftSize))
    var arrayMag = Array(repeating: Float(0), count: Int(buffersize/2))
    var dataBuffer = Buffer(with: 2048)
    var bpmTimer = Timer()
    var bpmResetTimer = Timer()
    var monitoringHr = false
    
    //-------------------------------------

    @IBOutlet weak var ldrLabel: UILabel!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var textBox: UITextField!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // MARK: CHANGE 1.a: change this as you no longer need to instantiate the BLE Object like this
        //   you should not let this ViewController be the BLE delegate
        //bleShield.delegate = self
        
        // MARK: CHANGE 4: Nothing to actually change here, just get familiar with
        //  the code below and what the notificaitons mean.
        // These selector functions should be created from the old BLEDelegate functions
        // One example has already been completed for you on the receiving of data function
        
        // BLE Connect Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onBLEDidConnectNotification),
                                               name: NSNotification.Name(rawValue: kBleConnectNotification),
                                               object: nil)
        
        // BLE Disconnect Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onBLEDidDisconnectNotification),
                                               name: NSNotification.Name(rawValue: kBleDisconnectNotification),
                                               object: nil)
        
        // BLE Recieve Data Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onBLEDidRecieveDataNotification),
                                               name: NSNotification.Name(rawValue: kBleReceivedDataNotification),
                                               object: nil)
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        
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
    // MARK: CHANGE 7: use function from "BLEDidConnect" notification
    // in this function, update a label on the UI to have the name of the active peripheral
    // you might be interested in the following method (from objective C):
    // NSString *deviceName =[notification.userInfo objectForKey:@"deviceName"];
    // NEW  CONNECT FUNCTION
    @objc func onBLEDidConnectNotification(notification:Notification){
        print("Notification arrived that BLE Connected")
        let deviceName = notification.userInfo?["name"] as! String?
        self.deviceLabel.text = deviceName
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                         repeats: true,
                                         block: self.readRSSITimer)
        bpmTimer = Timer.scheduledTimer(withTimeInterval: 2.0,
                                     repeats: true, block: self.getBpm)
    }
    
    // OLD DELEGATION CONNECT FUNCTION
//    func bleDidConnectToPeripheral() {
//        self.spinner.stopAnimating()
//        self.buttonConnect.setTitle("Disconnect", for: .normal)
//
//        // Schedule to read RSSI every 1 sec.
//        rssiTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
//                                         repeats: true,
//                                         block: self.readRSSITimer)
//
//    }
//
    // OLD DELEGATION DISCONNECT FUNCTION
//    func bleDidDisconnectFromPeripheral() {
//        // MARK: CHANGE 5.b: remove all accesses of the "connect button"
//        self.buttonConnect.setTitle("Connect", for: .normal)
//        rssiTimer.invalidate()
//    }
    
    // NEW  DISCONNECT FUNCTION
    @objc func onBLEDidDisconnectNotification(notification:Notification){
        print("Notification arrived that BLE Disconnected a Peripheral")
        rssiTimer.invalidate()
    }
    
    // OLD FUNCTION: parse the received data using BLEDelegate protocol
    func bleDidReceiveData(data: Data?) {
        // this data could be anything, here we know its an encoded string
        let s = String(bytes: data!, encoding: String.Encoding.utf8)
        labelText.text = s

    }
    //------------------------------------
    // NEW FUNCTION EXAMPLE: this was written for you to show how to change to a notification based model
    @objc func onBLEDidRecieveDataNotification(notification:Notification){
        let d = notification.userInfo?["data"] as! Data?
        let s = String(bytes: d!, encoding: String.Encoding.ascii)
        if (s?.index(of: "A") != nil){
            if(!monitoringHr){
                monitoringHr  = true
            }
            let startIndex = s?.index((s?.startIndex)!, offsetBy: 1)
            let endIndex = s?.index((s?.startIndex)!, offsetBy: 4)
            
            let hrData = s![startIndex!...endIndex!]
            //print(hrData)
            if let value = Float(hrData){
                self.dataBuffer.add(point: value)
                self.labelText.text = String(hrData)
            }
        }
        if (s?.index(of: "B") != nil){
            let startIndex = s?.index((s?.startIndex)!, offsetBy: 6)
            let ldrData = s![startIndex!...]
            self.ldrLabel.text = String(ldrData)
        }
    }
    //------------------------------------------
    // MARK: User initiated Functions
    // MARK: CHANGE 1.b: change this as you no longer need to search for perpipherals in this view controller
//    @IBAction func buttonScanForDevices(_ sender: UIButton) {
//
//        // disconnect from any peripherals
//        var didDisconnect = false
//        for peripheral in bleShield.peripherals {
//            if(peripheral.state == .connected){
//                if(bleShield.disconnectFromPeripheral(peripheral: peripheral)){
//                    didDisconnect = true
//                }
//            }
//        }
//        // if we disconnected anything, return from button
//        if(didDisconnect){
//            return
//        }
//
//        //start search for peripherals with a timeout of 3 seconds
//        // this is an asynchronous call and will return before search is complete
//        if(bleShield.startScanning(timeout: 3.0)){
//            // after three seconds, try to connect to first peripheral
//            Timer.scheduledTimer(withTimeInterval: 3.0,
//                                 repeats: false,
//                                 block: self.connectTimer)
//        }
//
//        // give connection feedback to the user
//        self.spinner.startAnimating()
//    }
    
    // MARK: CHANGE 1.c: change this as you no longer need to create the connection in this view controller
    // Called when scan period is over to connect to the first found peripheral
//    func connectTimer(timer:Timer){
//
//        if(bleShield.peripherals.count > 0) {
//            // connect to the first found peripheral
//            bleShield.connectToPeripheral(peripheral: bleShield.peripherals[0])
//        }
//        else {
//            self.spinner.stopAnimating()
//        }
//    }
    
    // MARK: CHANGE: this function only needs a name change, the BLE writing does not change
    @IBAction func sendDataButton(_ sender: UIButton) {
        
        let s = textBox.text!
        let d = s.data(using: String.Encoding.utf8)!
        bleShield.write(d)
        // if (self.textField.text.length > 16)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        var didDisconnect = false
        for peripheral in bleShield.peripherals {
            if(peripheral.state == .connected){
                if(bleShield.disconnectFromPeripheral(peripheral: peripheral)){
                    didDisconnect = true
                }
            }
        }
        bpmTimer.invalidate()
        // if we disconnected anything, return from button
        if(didDisconnect){
            return
        }
    }
    
    //----------------------------------------------------
    @IBAction func startLDR(_ sender: UIButton) {
        startLDRMonitor()
    }
    @IBAction func stopLDR(_ sender: UIButton) {
        stopLDRMonitor()
    }
    @IBAction func startHR(_ sender: UIButton) {
        startHeartRateMonitor()
    }
    @IBAction func stopHR(_ sender: UIButton) {
        stopHeartRateMonitor()
        
    }
    func startHeartRateMonitor() {
        //
        let command = "A"
        let d = command.data(using: String.Encoding.ascii)!
        bleShield.write(d)
    }
    func stopHeartRateMonitor()  {
        //
        let command = "B"
        let d = command.data(using: String.Encoding.ascii)!
        bleShield.write(d)
        bpmResetTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (ts) in
            self.monitoringHr = false
            self.dataBuffer.reset()
            self.labelText.text = "-"
            self.bpmLabel.text = "-"
        })
    }
    
    func startLDRMonitor() {
        //
        let command = "C"
        let d = command.data(using: String.Encoding.ascii)!
        bleShield.write(d)
        
    }
    func stopLDRMonitor()  {
        //
        let command = "D"
        let d = command.data(using: String.Encoding.ascii)!
        bleShield.write(d)
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { (ts) in
            self.ldrLabel.text = "-"
        })
        
    }

    
    func getBpm(timer:Timer) {
        
        let data = self.dataBuffer.getData()
        if (data.count != 0 && monitoringHr){
            let pad_size = ViewController.buffersize - data.count
            var zeroPaddedData = data + Array(repeating: Float(0), count: pad_size)
            
            fft!.performForwardFFT(withData: &zeroPaddedData, andCopydBMagnitudeToBuffer: &arrayMag)
            
            var peaks = finder!.getFundamentalPeaks(fromBuffer: &arrayMag, withLength: UInt(Int(ViewController.buffersize/2)),
                                                    usingWindowSize: 15, andPeakMagnitudeMinimum: 20, aboveFrequency: 60.0)
            
            if (peaks != nil){
                if peaks!.count > 0 {
                    let peak1: Peak = peaks![0] as! Peak
                    let res = Float(ViewController.samplingRate) / Float(ViewController.fftSize)
                    if peak1.frequency < 200{
                        self.bpmLabel.text = "BPM: "+String(peak1.frequency)
                    }else{
                        
                    }
                    
                    // print(arrayMag.max())
                    print("Freq resolution",res)
                    print("Heart rate is ",peak1.frequency)
                    
                }
            }
        }
    }
    //-------------------------------------------------------------
}








