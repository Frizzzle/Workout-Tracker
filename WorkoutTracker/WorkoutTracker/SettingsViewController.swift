//
//  SettingsViewControllers.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/1/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import Parse
import MBProgressHUD
let SEND_SECTION = 0
let WEIGHT_SECTION = 1
let DISTANCE_SECTION = 2

let KILOGRAM = 0
let POUNDS = 1

let KILLOMETERS = 0
let MILES = 1


class SettingViewController : UIViewController {
   
    var progressBar:MBProgressHUD!
    @IBOutlet weak var tableView: UITableView!
    
    var distance:Bool!
    var weight:Bool!
    override func viewDidLoad() {
        super.viewDidLoad()
        if (Settings.sharedInstance.currentDistanceUnit == str_km) {
           distance = true
        }else {
           distance = false
        }
        if (Settings.sharedInstance.currentWightUnit == str_kg) {
            weight = true
        }else {
            weight = false
        }
    
        self.navigationItem.title = str_Settings
        let editButton = UIBarButtonItem(title: str_Reset, style: UIBarButtonItemStyle.Done, target: self, action: "resetButtonClick")
        editButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16) ], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = editButton
        self.navigationController?.navigationBar.tintColor = UIColor(rgba: "#ff3e50ff")
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    func resetButtonClick() {
        let actionSheetController: UIAlertController = UIAlertController(title: str_ResetAppD, message:str_ResetSure, preferredStyle: .Alert)
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
        let gString = NSMutableAttributedString(string:str_ResetSure, attributes:attrs)
        actionSheetController.setValue(gString, forKey: "attributedMessage")
        
        
        let deleteAction: UIAlertAction = UIAlertAction(title: str_Reset, style: .Default) { action -> Void in
            self.progressBar = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            Settings.sharedInstance.isResetState = true
            let workoutStoreQuery = PFQuery(className: WOKROUTS_STORE)
            workoutStoreQuery.fromLocalDatastore()
            
            workoutStoreQuery.findObjectsInBackgroundWithBlock { (results, error ) -> Void in
                do {
                    for result in results! {
                        let name  = result["id"] as! String
                        let workoutResult = PFQuery(className: "class\(name)" )
                        workoutResult.fromLocalDatastore()
                        workoutResult.findObjectsInBackgroundWithBlock { (res, error ) -> Void in
                            do {
                                try PFObject.unpinAll(res)
                            }catch {
                                
                            }
                        }
                        
                    }
                    try PFObject.unpinAll(results!)
                    
                }catch {
                    
                }
                
            }
            ExerciseManager.sharedInstance.resetByDefault({ () -> Void in
                UserExercisesManager.sharedInstance.resetByDefault({ () -> Void in
                    let historyStore = PFQuery(className: "SettingStore")
                    historyStore.fromLocalDatastore()
                    historyStore.findObjectsInBackgroundWithBlock { (results, error ) -> Void in
                        do {
                            try PFObject.unpinAll(results!)
                            let historyStore = PFQuery(className: "Lang")
                            historyStore.fromLocalDatastore()
                            historyStore.findObjectsInBackgroundWithBlock { (results, error ) -> Void in
                                do {
                                    try PFObject.unpinAll(results!)
                                    Settings.sharedInstance.saveSettingState(str_km, weightUnit: "")
                                    Settings.sharedInstance.saveSettingState("", weightUnit: str_kg)
                                    self.distance = true
                                    self.weight = true
                                    self.progressBar.hide(true)
                                    self.tabBarController?.selectedIndex = 0
                                }catch {
                                    
                                }
                                
                            }
                            
                        }catch {
                            
                        }
                        
                    }

                })
            })
        }
        actionSheetController.addAction(deleteAction)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: str_Cancel, style: .Default) { action -> Void in
        }
        actionSheetController.addAction(cancelAction)
        self.presentViewController(actionSheetController, animated: true, completion: nil)
       
    }
    
      override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["feedback@liftapp.me"])
        mailComposerVC.setSubject("Lift App Feedback")
        mailComposerVC.setMessageBody("", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
}

extension SettingViewController : MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension SettingViewController : UITableViewDataSource,UITableViewDelegate {

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
        //tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch(indexPath.section) {
        case SEND_SECTION :
            let mailComposeViewController = configuredMailComposeViewController()
            if MFMailComposeViewController.canSendMail() {
                self.presentViewController(mailComposeViewController, animated: true, completion: nil)
            } else {
                self.showSendMailErrorAlert()
            }
            break
        case WEIGHT_SECTION :
            switch(indexPath.row) {
            case KILOGRAM :
                if(self.weight == true) {
                    return
                }else {
                    self.weight = true
                    Settings.sharedInstance.saveSettingState("", weightUnit: str_kg)
                    tableView.reloadData()
                }
                break
            case POUNDS :
                if(self.weight == false) {
                    return
                }else {
                    self.weight = false
                    Settings.sharedInstance.saveSettingState("", weightUnit: str_lb)
                    tableView.reloadData()
                }
                break
            default:
                break
            }
            break
        case DISTANCE_SECTION :
            switch(indexPath.row) {
            case KILLOMETERS :
                if(self.distance == true) {
                    return
                }else {
                    self.distance = true
                    Settings.sharedInstance.saveSettingState(str_km, weightUnit: "")
                    tableView.reloadData()
                }
                break
            case MILES :
                if(self.distance == false) {
                    return
                }else {
                    self.distance = false
                    Settings.sharedInstance.saveSettingState(str_mi, weightUnit: "")
                    tableView.reloadData()
                }
                break
            default:
                break
            }
            break

        default:
            break
        }

    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0) {
            return 1
        }
        return 2;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingCell") as? SettingCell
        //cell!.titleText.font = UIFont(name: "SanFranciscoText-Medium", size: 17)
        switch(indexPath.section) {
        case SEND_SECTION :
            cell!.titleText.text = str_FeedBack
            cell!.imgView.image = nil
            cell!.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            break
        case WEIGHT_SECTION :
            switch(indexPath.row) {
            case KILOGRAM :
                cell!.titleText.text = str_Kilograms
                if(self.weight == true){
                    cell!.imgView.image = UIImage(named: "checked_icon")
                }else {
                    cell!.imgView.image = nil
                }
                break
            case POUNDS :
                cell!.titleText.text = str_Pounds
                if(self.weight == false){
                    cell!.imgView.image = UIImage(named: "checked_icon")
                }else {
                   cell!.imgView.image = nil
                }
                break
            default:
                break
            }
            break
        case DISTANCE_SECTION :
            switch(indexPath.row) {
            case KILLOMETERS :
                cell!.titleText.text = str_Kilometers
                if(self.distance == true){
                    cell!.imgView.image = UIImage(named: "checked_icon")
                }else {
                    cell!.imgView.image = nil
                }
                break
            case MILES :
                cell!.titleText.text = str_Miles
                if(self.distance == false){
                    cell!.imgView.image = UIImage(named: "checked_icon")
                }else {
                    cell!.imgView.image = nil
                }
                break
            default:
                break
            }
            break
        default:
            break
        }
        
        return cell!
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return ""
        }else if (section == 1) {
            return str_WU
        }else {
            return str_DU
        }

    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 0.94 , green: 0.94, blue: 0.94, alpha: 1);
        
        // if you have index/header text in your tableview change your index text color
        let headerIndexText = view as! UITableViewHeaderFooterView
        headerIndexText.textLabel?.textColor = UIColor(rgba: "#000000")
        //headerIndexText.textLabel?.font =  UIFont(name: "SanFranciscoText-Medium", size: 17)
    }
}