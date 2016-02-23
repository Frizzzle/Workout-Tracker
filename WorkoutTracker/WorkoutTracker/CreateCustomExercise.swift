//
//  File.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/6/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD
class CreateCustomExercise: UIViewController {
    @IBOutlet var exerciseName: UITextField!
    @IBOutlet var weightCheck: UIImageView!
    @IBOutlet var weightCkeckView: UIView!
    @IBOutlet var distanceCheck: UIImageView!
    @IBOutlet var distanceCheckView: UIView!
    var delegate:AddExerciseVCProtocol?
    var newItem:Exercise!
    var isSaving:Bool!
    var progressHUD:MBProgressHUD!

    var owner:AddExerciseVC?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.exerciseName.becomeFirstResponder()
        isSaving = false
        newItem = Exercise(id: "", name: "", usedCount: 0, type: "Distance",isCustom: true)
        
        self.navigationItem.setHidesBackButton(false, animated: false)
        let saveButton = UIBarButtonItem(title: str_Save, style: UIBarButtonItemStyle.Done, target: self, action: "saveButtonClick")
        self.navigationItem.rightBarButtonItem = saveButton
        let cancelButton = UIBarButtonItem(title: str_Cancel, style: UIBarButtonItemStyle.Done, target: self, action: "cancelButtonClick")
        cancelButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16) ], forState: UIControlState.Normal)
        self.navigationItem.leftBarButtonItem = cancelButton
        
        self.navigationController?.navigationBar.tintColor = UIColor(rgba: "#ff3e50ff")
        self.navigationItem.title = str_CrCuEx
        
        self.weightCheck.image = UIImage(named: "checked_icon")
        newItem.type = "Weight"
        
        self.distanceCheck.image = nil
        
        let weightGesture = UITapGestureRecognizer(target: self, action: "weightCheckTap")
        self.weightCkeckView.addGestureRecognizer(weightGesture)
        
        let distanceGesture = UITapGestureRecognizer(target: self, action: "distanceCheckTap")
        self.distanceCheckView.addGestureRecognizer(distanceGesture)
    }
    func weightCheckTap() {
        if (newItem.type == "Distance") {
            newItem.type = "Weight"
            self.weightCheck.image = UIImage(named: "checked_icon")
            self.distanceCheck.image = nil
        }
    }
    func distanceCheckTap() {
        if (newItem.type == "Weight") {
            newItem.type = "Distance"
            self.distanceCheck.image = UIImage(named: "checked_icon")
            self.weightCheck.image = nil
        }
    }
    func saveButtonClick() {
        if(self.isSaving == true) {
            return
        }
        self.isSaving = true
        if(self.exerciseName.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty == true) {
            let nameEmptyAlert: UIAlertController = UIAlertController(title: "", message: str_PlsInpWorkoutName, preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: str_Close, style: .Cancel, handler: {(alert: UIAlertAction!) in
                self.isSaving = false
                if(self.progressHUD != nil) {
                   self.progressHUD.hide(true) 
                }
            })
            nameEmptyAlert.addAction(cancelAction)
            self.presentViewController(nameEmptyAlert, animated: true, completion: nil)
            return
        }
        
        self.newItem.exerciseName = self.exerciseName.text
        self.newItem.usedCount = 0;
        saveNewItem()
        
    }
    func saveNewItem() {
        progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        progressHUD.labelText = str_Saving
        progressHUD.show(true)
        ExerciseManager.sharedInstance.createNewExercise(newItem, exist: { () -> Void in
            let nameExistAlert: UIAlertController = UIAlertController(title: "", message: str_ExExistName, preferredStyle: .Alert)
            let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
            let gString = NSMutableAttributedString(string:str_ExExistName, attributes:attrs)
            nameExistAlert.setValue(gString, forKey: "attributedMessage")
            let cancelAction = UIAlertAction(title: str_Close, style: .Cancel, handler: {(alert: UIAlertAction!) in
                self.isSaving = false
                self.progressHUD.hide(true)
            })
            
            nameExistAlert.addAction(cancelAction)
            self.presentViewController(nameExistAlert, animated: true, completion: nil)
        }, success: { () -> Void in
            self.progressHUD.hide(true)
            self.delegate?.addNewCustomExercise(self.newItem)
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)

        })
    }
    func cancelButtonClick() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
