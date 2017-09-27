//
//  TableViewController.swift
//  ExampleRedBearChat
//
//  Created by Eric Larson on 9/26/17.
//  Copyright © 2017 Eric Larson. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    // on access, setup this variable
    lazy var bleShield:BLE = (UIApplication.shared.delegate as! AppDelegate).bleShield
        
    override func viewDidLoad() {
        super.viewDidLoad()

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(scanForDevices), for: .valueChanged)
        self.refreshControl = refresh
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bleShield.peripherals.count
    }
    
    @objc func scanForDevices() {
        
        // disconnect from any peripherals
        for peripheral in bleShield.peripherals {
            if(peripheral.state == .connected){
                bleShield.disconnectFromPeripheral(peripheral: peripheral)
            }
        }
        
        //start search for peripherals with a timeout of 3 seconds
        // this is an asynchronous call and will return before search is complete
        if(bleShield.startScanning(timeout: 3.0)){
            // after three seconds, try to connect to first peripheral
            Timer.scheduledTimer(withTimeInterval: 3.0,
                                 repeats: false,
                                 block: self.didFinishScanning)
        }
        
    }
    
    func didFinishScanning(timer:Timer){
        self.tableView.reloadData()
        self.refreshControl?.endRefreshing()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "simpleCell", for: indexPath)

        let peripheral = self.bleShield.peripherals[indexPath.row]
        cell.textLabel?.text = peripheral.name!
        cell.detailTextLabel?.text = peripheral.identifier.uuidString

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
