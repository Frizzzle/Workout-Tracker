    //
//  WorkoutViewController.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 9/30/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import Darwin
import Foundation
import Parse
import MBProgressHUD

let ADD_WORKOUT_TAG  = 0
let WORKOUT_TAG = 1
let WOKROUTS_STORE = "Aorkouts"
    let DEFOULT_WEIGHT_COUNT = defaultExercises.count - 12
    let defaultExercises = [    str_1,
        str_2,
        str_3,
        str_4,
        str_5,
        str_6,
        str_7,
        str_8,
        str_9,
        str_10,
        str_11,
        str_12,
        str_13,
        str_14,
        str_15,
        str_16,
        str_17,
        str_18,
        str_19,
        str_20,
        str_21,
        str_22,
        str_23,
        str_24,
        str_25,
        str_26,
        str_27,
        str_28,
        str_29,
        str_30,
        str_31,
        str_32,
        str_33,
        str_34,
        str_35,
        str_36,
        str_37,
        str_38,
        str_39,
        str_40,
        str_41,
        str_42,
        str_43,
        str_44,
        str_45,
        str_46,
        str_47,
        str_48,
        str_49,
        str_50,
        str_51,
        str_52,
        str_53,
        str_54,
        str_55,
        str_56,
        str_57,
        str_58,
        str_59,
        str_60,
        str_61,
        str_62,
        str_63,
        str_64,
        str_65,
        str_66,
        str_67,
        str_68,
        str_69,
        str_70,
        str_71,
        str_72,
        str_73,
        str_74,
        str_75,
        str_76,
        str_77,
        str_78,
        str_79,
        str_80,
        str_81,
        str_82,
        str_83,
        str_84,
        str_85,
        str_86,
        str_87,
        str_88,
        str_89,
        str_90,
        str_91,
        str_92,
        str_93,
        str_94]

class WorkoutViewController : UIViewController  {
    var progressHUD:MBProgressHUD!
    var array: Array<WorkoutTemplate>!
    var counts: Array<Int>!
    var selectedWorkout:Int!
    var supportTextField:UITextField!
    var count:Int!
    var selectedItem:Int!
    var deleteView:UIView!
    var loaded:Bool!
    var dashedLayer:CAShapeLayer?
    var isNew:Bool!
    var preId:String!
    var standartExercises:[String]!
    var newWorkout:PFObject?
    var countDict:[String:Int]!
    @IBOutlet var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem!.title = str_Workouts
        
        self.tabBarController?.tabBar.tintColor = UIColor(rgba: "#ff3e50ff")
        renameCheck()
        ExerciseManager.sharedInstance;
        UserExercisesManager.sharedInstance;
        loaded = false
        array = Array<WorkoutTemplate>()
        counts = Array<Int>()
        countDict = [String: Int]()
        
        do {
            let isFirst:Bool? = try PFQuery(className: "ISFIRST").fromLocalDatastore().getFirstObject()["isFirst"] as? Bool
            if(isFirst == false) {
                
            }else {
                self.array.append(WorkoutTemplate(id: "-1",name: "last"))
                loadWorkouts()
            }
        }catch {
            
            let object =  PFObject(className: "ISFIRST")
            object["isFirst"] = true
            object.pinInBackground()
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
                
                // ...Run some task in the background here...
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.preLoadFistWorkout()
                    
                    
                    // ...Run something once we're done with the background task...
                }
            }

            
        }
        
        
        
        
    }
    
    func renameCheck(){
        let langQ = PFQuery(className: "Lang")
        langQ.fromLocalDatastore()
        
        langQ.getFirstObjectInBackgroundWithBlock({ (lang, error ) -> Void in
            if(error != nil) {
                return
            }
            if((lang!["lang"] as! String) != NSLocale.preferredLanguages()[0]) {
                lang!["lang"] = NSLocale.preferredLanguages()[0]
                lang!.pinInBackground()
                ExerciseManager.sharedInstance.renameAll()
            }
        })
        
        
    }
    
    func removeExerciseUsed(workoutId:String){
            let query = PFQuery(className: workoutId)
            query.fromLocalDatastore()
            query.findObjectsInBackgroundWithBlock { (result, errr) -> Void in
                for var k = 0; k < result?.count; k = k + 1 {
                    let res = result?[k]
                    res!.unpinInBackground()
                    ExerciseManager.sharedInstance.decreaseExerciseCount(res!["exerciseId"] as! String)
                }
                
            }
            


    }
    
    func preLoadExercises(){
        self.standartExercises = [String]()
        ExerciseManager.sharedInstance.firstLoadExercises { (standarts) -> Void in
            self.standartExercises = standarts
            self.preLoadSavingExerciseInWorkout()
        }
    }
    
    func preLoadSavingExerciseInWorkout() {
        var count = 1
        var qCount = self.standartExercises.count
        progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated:true)
        var array = [PFObject]()
        for item in self.standartExercises {
            ExerciseManager.sharedInstance.increaseExerciseCount(item)
            let newExerciseInWorkout = PFObject(className: self.preId)
            newExerciseInWorkout["exerciseId"] = item
            newExerciseInWorkout["exercisePriority"] = count
            count = count + 1
            array.append(newExerciseInWorkout)
        }
        ExerciseManager.sharedInstance.count = array.count
        PFObject.pinAllInBackground(array) { (success, error ) -> Void in
            if(success) {
                ExerciseManager.sharedInstance.count = -1
            }
        }
        self.progressHUD.hide(true)
        self.collectionView.delegate = nil;
        self.collectionView.dataSource = nil;
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.array.removeAll();
        self.array.append(WorkoutTemplate(id: "-1",name: "last"))
        self.loadWorkouts()

    }
    
    func preLoadFistWorkout() {
        let newWorkout = PFObject(className: WOKROUTS_STORE)
        
        newWorkout.setValue("Lower Body", forKey: "name")
        newWorkout.ownSaveEventually({ (isSuccess, err ) -> Void in
            if(isSuccess == true) {
                newWorkout.pinInBackground()
                self.preId = "class" + (newWorkout["id"] as! String)
                self.countDict[self.preId] = 5
                self.preLoadExercises()

            }
        })
        
    }
    
    func loadWorkouts() {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {

        
        let templateQuery = PFQuery(className: WOKROUTS_STORE)
        templateQuery.fromLocalDatastore()
        templateQuery.findObjectsInBackgroundWithBlock { (templates, error) -> Void in
            
            for object in templates! {
                let name = object.valueForKey("name") as! String
                let id = object["id"] as! String
                self.array.append(WorkoutTemplate(id: id,name: name))
                let countQuery = PFQuery(className: id)
                countQuery.fromLocalDatastore()
                countQuery.whereKey("checked", equalTo: true)
                //let a  = countQuery.countObjects(NSErrorPointer())
                self.counts.append(countQuery.countObjects(NSErrorPointer()))

            }
            if(templates?.count != 0) {
                if(self.array[0].workoutName == "last"){
                    self.array.removeFirst()
                    self.array.append(WorkoutTemplate(id: "-1",name: "last"))
                }
            }
            for ind in 0...self.array.count {
                self.counts.append(ind)
            }
            self.loaded = true
            dispatch_async(dispatch_get_main_queue()) {
                
                self.collectionView.reloadData()
            }
            
        }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if(Settings.sharedInstance.isResetState == true) {
            ExerciseManager.sharedInstance.loadExercise()
            UserExercisesManager.sharedInstance.loadHistory()
            Settings.sharedInstance.isResetState = false
            loaded = false
            array = Array<WorkoutTemplate>()
            counts = Array<Int>()
            self.array.append(WorkoutTemplate(id: "-1",name: "last"))
            
            preLoadFistWorkout()
            
        }
        self.countDict.removeAll()
        self.collectionView.reloadData()
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "workoutDetail") {
            //let addExerciseNC = segue.destinationViewController as! UINavigationController
            let exercisesInWorkoutVC = segue.destinationViewController as! ExercisesInWorkoutVC
            let backItem = UIBarButtonItem()
            backItem.title = " "
            navigationItem.backBarButtonItem = backItem
            if(self.isNew == false) {
                exercisesInWorkoutVC.workoutId = array[selectedItem].workoutId
                exercisesInWorkoutVC.workoutName = array[selectedItem].workoutName
                exercisesInWorkoutVC.cont = self.countDict["class" + array[selectedItem].workoutId]
                exercisesInWorkoutVC.isNew = false
            }else {
                exercisesInWorkoutVC.isNew = true
                exercisesInWorkoutVC.workoutId = self.newWorkout!["id"] as! String
                exercisesInWorkoutVC.workoutName = self.supportTextField.text
                self.array.removeLast()
                self.array.append(WorkoutTemplate(id: self.newWorkout!["id"] as! String,name: self.supportTextField.text!))
                self.array.append(WorkoutTemplate(id: "-1",name: "last"))
                
                //self.navigationController?.pushViewController(exercisesInWorkoutVC, animated: true)
                self.collectionView.reloadData()
                
            }
        }
    }
    
    func countsA(var str:String) -> Int{
        str = "class" + str
        if let _ = countDict[str] {
            return countDict[str]!
        }
        let templateQuery = PFQuery(className: str)
        templateQuery.fromLocalDatastore()
        countDict[str] = templateQuery.countObjects(NSErrorPointer())
        return (countDict[str])!
    
    }
    func del(str:String){
        
        let templateQuery = PFQuery(className: WOKROUTS_STORE)
        templateQuery.fromLocalDatastore()
        templateQuery.whereKey("id", equalTo: str)
        templateQuery.findObjectsInBackgroundWithBlock { (res, ErrorType) -> Void in
            res?[0].unpinInBackground()
        }
        removeExerciseUsed("class" + str)
        
    }
    
    // MARK: taps on view
    func createNewTap(gestureRecognizer: UIGestureRecognizer) {
        
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: str_NameNewWorkout, preferredStyle: .Alert)
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
        let gString = NSMutableAttributedString(string:str_NameNewWorkout, attributes:attrs)
        actionSheetController.setValue(gString, forKey: "attributedMessage")
        let cancelAction: UIAlertAction = UIAlertAction(title: str_Cancel, style: .Default) { action -> Void in
            self.supportTextField = nil
        }
        
        
        let createAction: UIAlertAction = UIAlertAction(title: str_CreateWorkout, style: .Default) { action -> Void in
            
            if(self.supportTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty == true) {
                let nameEmptyAlert: UIAlertController = UIAlertController(title: "", message: str_PlsInpWorkoutName, preferredStyle: .Alert)
                let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
                let gString = NSMutableAttributedString(string:str_PlsInpWorkoutName, attributes:attrs)
                actionSheetController.setValue(gString, forKey: "attributedMessage")
                let cancelAction = UIAlertAction(title: str_Close, style: .Cancel) { action -> Void in
                    self.createNewTap(gestureRecognizer)
                }
                nameEmptyAlert.addAction(cancelAction)
                self.presentViewController(nameEmptyAlert, animated: true, completion: nil)
                return
            }else {
                if(!self.isUnic(self.supportTextField.text!)) {
                    let nameExistAlert: UIAlertController = UIAlertController(title: "", message: str_ExstWorkNameNew, preferredStyle: .Alert)
                    let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
                    let gString = NSMutableAttributedString(string:str_ExstWorkNameNew, attributes:attrs)
                    nameExistAlert.setValue(gString, forKey: "attributedMessage")
                    let cancelAction = UIAlertAction(title: str_Close, style: .Cancel, handler: {(alert: UIAlertAction!) in
                        self.createNewTap(gestureRecognizer)
                    })
                    nameExistAlert.addAction(cancelAction)
                    self.presentViewController(nameExistAlert, animated: true, completion: nil)
                    
                    return
                }

            }
            self.isNew = true
            let newW = PFObject(className: WOKROUTS_STORE)
            
            newW.setValue(self.supportTextField.text, forKey: "name")
            newW.ownSaveEventually({ (isSuccess, err ) -> Void in
                if(isSuccess == true) {
                    self.newWorkout = newW;
                    newW.pinInBackground()
                    self.performSegueWithIdentifier("workoutDetail", sender: self)
                }
            })
            
        }
        actionSheetController.addAction(createAction)
        actionSheetController.addAction(cancelAction)
        
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            
            textField.placeholder = str_InpWorkName
            self.supportTextField = textField
            self.supportTextField.spellCheckingType = UITextSpellCheckingType.Yes
            self.supportTextField.autocorrectionType = UITextAutocorrectionType.Yes
            self.supportTextField.autocapitalizationType = UITextAutocapitalizationType.Sentences
        }
        
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    func showRenameDialog(){
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .Alert)
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
        let gString = NSMutableAttributedString(string:"\(str_Rename) \(self.array[self.selectedWorkout].workoutName) \(str_workout)", attributes:attrs)
        actionSheetController.setValue(gString, forKey: "attributedTitle")
        let cancelAction: UIAlertAction = UIAlertAction(title: str_Cancel, style: .Default) { action -> Void in
            self.supportTextField = nil
        }
        actionSheetController.addAction(cancelAction)
        
        let renameAction: UIAlertAction = UIAlertAction(title: str_Rename, style: .Default) { action -> Void in
            
            if(self.supportTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty == true) {
                let nameEmptyAlert: UIAlertController = UIAlertController(title: "", message: str_PlsInpWorkoutName, preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: str_Cancel, style: .Cancel) { action -> Void in
                    self.showRenameDialog()
                }
                nameEmptyAlert.addAction(cancelAction)
                self.presentViewController(nameEmptyAlert, animated: true, completion: nil)
                return
            }else {
            if(!self.isUnic(self.supportTextField.text!) && (self.supportTextField.text != self.array[self.selectedWorkout].workoutName)) {
                let nameExistAlert: UIAlertController = UIAlertController(title: "", message: str_WorkNameNew, preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: str_Close, style: .Cancel, handler: {(alert: UIAlertAction!) in
                    self.showRenameDialog()
                })
                nameExistAlert.addAction(cancelAction)
                self.presentViewController(nameExistAlert, animated: true, completion: nil)
                
                return
            }
            }
            self.array[self.selectedWorkout].workoutName = self.supportTextField.text!
            self.renameInStore(self.supportTextField.text!, currID: self.array[self.selectedWorkout].workoutId)
            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: self.selectedWorkout, inSection: 0)])
        }
        
        actionSheetController.addAction(renameAction)
        
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            
            textField.text = self.array[self.selectedWorkout].workoutName
            self.supportTextField = textField
            self.supportTextField.spellCheckingType = UITextSpellCheckingType.Yes
            self.supportTextField.autocorrectionType = UITextAutocorrectionType.Yes
        }
        
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    func renameInStore(newName:String,currID:String) {
        let queryForRename = PFQuery(className: WOKROUTS_STORE)
        queryForRename.fromLocalDatastore()
        queryForRename.whereKey("id" , equalTo: currID)
        queryForRename.findObjectsInBackgroundWithBlock { (renamesObject, error) -> Void in
            renamesObject?[0].setValue(newName, forKey: "name")
            renamesObject?[0].pinInBackground()
        }
    }
    
    func showDeleteDialog(){
        let actionSheetController: UIAlertController = UIAlertController(title: "\(str_Delete) \(self.array[self.selectedWorkout].workoutName) \(str_workout)", message: str_DelWork, preferredStyle: .Alert)
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
        let gString = NSMutableAttributedString(string:str_DelWork, attributes:attrs)
        actionSheetController.setValue(gString, forKey: "attributedMessage")

        
        let deleteAction: UIAlertAction = UIAlertAction(title: str_Delete, style: .Default) { action -> Void in
            if let recognizers = self.deleteView.gestureRecognizers {
                for recognizer in recognizers {
                    self.deleteView.tag = -1
                    self.deleteView.removeGestureRecognizer(recognizer )
                }
            }
            if let recognizers = self.deleteView.gestureRecognizers {
                for recognizer in recognizers {
                    self.deleteView.removeGestureRecognizer(recognizer )
                }
            }

            self.del(self.array[self.selectedWorkout].workoutId)
            self.array.removeAtIndex(self.selectedWorkout)
            self.collectionView.reloadData()
        }
        actionSheetController.addAction(deleteAction)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: str_Cancel, style: .Default) { action -> Void in
        }
        actionSheetController.addAction(cancelAction)
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func settingTap(gestureRecognizer: UIGestureRecognizer) {
        selectedWorkout = gestureRecognizer.view?.tag
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let renameAction = UIAlertAction(title: str_Rename, style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showRenameDialog()
        })
        let deleteAction = UIAlertAction(title: str_Delete, style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.deleteView = gestureRecognizer.view
            self.showDeleteDialog()
        })
        let cancelAction = UIAlertAction(title: str_Cancel, style: .Cancel, handler: nil)
        optionMenu.addAction(renameAction)
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func workoutTap(gestureRecognizer: UIGestureRecognizer) {
        isNew = false
        self.performSegueWithIdentifier("workoutDetail", sender: self)

    }
    // MARK: switch color
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSizeMake((self.view.frame.size.width - 50)/2, (self.view.frame.size.width - 50)/2)
    }
    func swichColor(index:NSIndexPath) -> CGColor {
        var selectedColor = UIColor()
        let colorItem = index.row % 5
        switch (colorItem){
        case 0:
            selectedColor = UIColor(rgba: "#ff4051")
            break;
        case 1:
            selectedColor = UIColor(rgba: "#00e295")
            break;
        case 2:
            selectedColor = UIColor(rgba: "#ff2990")
            break;
        case 3:
            selectedColor = UIColor(rgba: "#00c5ff")
            break;
        case 4:
            selectedColor = UIColor(rgba: "#ae5bff")
            break;
        default :
            break;
        }
        
        
        return selectedColor.CGColor
    }
    func swichSelectedColor(index:NSIndexPath) -> CGColor {
        var selectedColor = UIColor()
        let colorItem = index.row % 5
        switch (colorItem){
        case 0:
            selectedColor = UIColor(rgba: "#dc1E37")
            break;
        case 1:
            selectedColor = UIColor(rgba: "#00c878")
            break;
        case 2:
            selectedColor = UIColor(rgba: "#dc0073")
            break;
        case 3:
            selectedColor = UIColor(rgba: "#00a3dc")
            break;
        case 4:
            selectedColor = UIColor(rgba: "#903ddc")
            break;
        default :
            break;
        }
        
        
        return selectedColor.CGColor
    }
    
        
    

    

}

extension  WorkoutViewController :UICollectionViewDataSource,UICollectionViewDelegate  {
    //MARK: overrides
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return array.count
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {        
        if(indexPath.row == array.count - 1) {
            
            self.createNewTap(UITapGestureRecognizer())
            
        } else {
            selectedItem = indexPath.row
            //cell?.layer.backgroundColor = UIColor.clearColor().CGColor
            self.workoutTap(UITapGestureRecognizer())
        }
    }
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView.cellForItemAtIndexPath(indexPath)
        if(indexPath.row == array.count - 1 ) {
            return
        }
        cell?.layer.backgroundColor = swichSelectedColor(indexPath)
    }
    func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView.cellForItemAtIndexPath(indexPath)
        if(indexPath.row == array.count - 1 ) {
            return
        }
        cell?.layer.backgroundColor = swichColor(indexPath)
    }

    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        if(indexPath.row == array.count - 1) {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CustomWorkoutCell

            let titleText = "+ \n"
            let subTitleText = str_CrtWork
            cell.layer.backgroundColor = UIColor.clearColor().CGColor
            let string =  (titleText  + subTitleText) as NSString
            let attributedString = NSMutableAttributedString(string: string as String)
            
            let title = [NSFontAttributeName : UIFont.systemFontOfSize(40) , NSForegroundColorAttributeName: UIColor(rgba: "#000000a5")]
            let subtitle = [NSFontAttributeName : UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor(rgba: "#000000a5")]
            
            attributedString.addAttributes(title, range: string.rangeOfString(titleText))
            attributedString.addAttributes(subtitle, range: string.rangeOfString(subTitleText))

//            let labelGestureRecognizer = UITapGestureRecognizer(target: self, action: "createNewTap:")
//            cell.tapView.addGestureRecognizer(labelGestureRecognizer)
            cell.MainLabel.attributedText = attributedString
       
            cell.settings.hidden = true;
  
            drawDaashedBorderAroundView(cell)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CustomWorkoutCell
            
            cell.layer.cornerRadius = 20.0;
            
            cell.layer.backgroundColor = swichColor(indexPath)
            cell.selectedBackgroundView?.backgroundColor = UIColor(CGColor: swichColor(NSIndexPath(index: indexPath.row + 1 )))
            var titleText = "\(array[indexPath.row].workoutName)\n"
            let count = countsA(array[indexPath.row].workoutId)
            var subTitleText = "\n"
            
//            if(count == 1) {
//                subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISE)"
//            }else {
//                subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISES)"
//            }
            
            if( NSLocale.preferredLanguages()[0] != "ru") {
                if(count == 1) {
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISE)"
                }else {
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISES)"
                }
            }else {
                if(count == 1) {
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISE)"
                }else if(count > 10) && (count < 20) {
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISER)"
                }else if(((count % 10) == 2)||((count % 10) == 3)||((count % 10) == 4)){
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISES)"
                }else if((count % 10) > 4) {
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISER)"
                }else if((count % 10) == 0){
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISER)"
                }else if((count % 10) == 1){
                    subTitleText = subTitleText + "\(countsA(array[indexPath.row].workoutId)) \(str_EXERCISE)"
                }
            }
            
            let font = UIFont.systemFontOfSize(20)
            var detailHeight = heightForLabel(titleText, font: font, width: cell.bounds.size.width)
            let font1 = UIFont.systemFontOfSize(12)
            detailHeight = detailHeight + heightForLabel(subTitleText, font: font1, width: cell.bounds.size.width)
                        
            while(detailHeight > (cell.frame.height - 20)) {
                
                var i =  5
                while(i != 0 ) {
                    titleText.removeAtIndex(titleText.endIndex.predecessor())
                    i = i - 1
                }
                titleText = titleText + "...\n"
                detailHeight = heightForLabel(titleText, font: font, width: cell.bounds.size.width)
                detailHeight = detailHeight + heightForLabel(subTitleText, font: font1, width: cell.bounds.size.width)
                
            }
            
            
            let string =  (titleText  + subTitleText) as NSString
            
            let attributedString = NSMutableAttributedString(string: string as String)
            
            let title = [NSFontAttributeName: UIFont.systemFontOfSize(20), NSForegroundColorAttributeName: UIColor(rgba: "#ffffff")]
            let subtitle = [NSFontAttributeName : UIFont.systemFontOfSize(12), NSForegroundColorAttributeName: UIColor(rgba: "#ffffffa5")]
            
            attributedString.addAttributes(title, range: string.rangeOfString(titleText))
            attributedString.addAttributes(subtitle, range: string.rangeOfString(subTitleText))
            
            let settingGestureRecognizer = UITapGestureRecognizer(target: self, action: "settingTap:")
            cell.settings.addGestureRecognizer(settingGestureRecognizer)
            cell.settings.tag = indexPath.row
            cell.settings.hidden = false;
            cell.tapView.tag = indexPath.row
            
            cell.MainLabel.attributedText = attributedString
            
            cell.tag = WORKOUT_TAG
            var index = 0
            while(index != cell.layer.sublayers?.count) {
                if let _ = cell.layer.sublayers?[index] as? CAShapeLayer {
                    cell.layer.sublayers?.removeAtIndex(index)
                }
                else {
                    index++
                }
            }

            return cell

        }
    }
    func heightForLabel(text:String, font:UIFont, width:CGFloat) -> CGFloat
    {
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
        
    }
    func isUnic(str:String!) -> Bool {
        
        if(self.array.filter() {$0.workoutName == str}.count == 0) {
            return true
        }else {
            return false
        }
    }
    
  // MARK: dashBorder
    func drawDaashedBorderAroundView(v:UIView) -> Void {

        let cornerRadius:CGFloat = 20.0
        let borderWidth:CGFloat  = 2.0
        let lineColor = UIColor(rgba: "#979797a5")
        
        //drawing
        let frame = v.bounds
        
        let _shapeLayer = CAShapeLayer()
        //creating a path
        let path = CGPathCreateMutable()
        
        //drawing a border around a view
        CGPathMoveToPoint(path, nil, 0, frame.size.height - cornerRadius)
        CGPathAddLineToPoint(path, nil, 0, cornerRadius)
        CGPathAddArc(path, nil, cornerRadius, cornerRadius, cornerRadius, CGFloat(M_PI), -CGFloat(M_PI_2), false)
        CGPathAddLineToPoint(path, nil, frame.size.width - cornerRadius, 0)
        CGPathAddArc(path, nil, frame.size.width - cornerRadius, cornerRadius, cornerRadius, -CGFloat(M_PI_2), 0, false)
        CGPathAddLineToPoint(path, nil, frame.size.width, frame.size.height - cornerRadius)
        CGPathAddArc(path, nil, frame.size.width - cornerRadius, frame.size.height - cornerRadius, cornerRadius, 0, CGFloat(M_PI_2), false)
        CGPathAddLineToPoint(path, nil, cornerRadius, frame.size.height)
        CGPathAddArc(path, nil, cornerRadius, frame.size.height - cornerRadius, cornerRadius, CGFloat(M_PI_2), CGFloat(M_PI), false)
        
        //path is set as the _shapeLayer object's path
        _shapeLayer.path = path
        
        
        _shapeLayer.backgroundColor = UIColor.clearColor().CGColor
        _shapeLayer.frame = frame
        _shapeLayer.masksToBounds = false
        _shapeLayer.setValue(NSNumber(bool: false), forKey: "isCircle")
        _shapeLayer.fillColor = UIColor.clearColor().CGColor
        _shapeLayer.strokeColor = lineColor.CGColor
        _shapeLayer.lineWidth = borderWidth
        _shapeLayer.lineDashPattern = Array.init(count: 5, repeatedValue: 5)
        _shapeLayer.lineCap = kCALineCapRound
        
        //_shapeLayer is added as a sublayer of the view, the border is visible
        v.layer.addSublayer(_shapeLayer)
        v.layer.cornerRadius = cornerRadius
    }

}
public extension UIColor {
    public convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0
        
        if rgba.hasPrefix("#") {
            let index   = rgba.startIndex.advancedBy(1)
            let hex     = rgba.substringFromIndex(index)
            let scanner = NSScanner(string: hex)
            var hexValue: CUnsignedLongLong = 0
            if scanner.scanHexLongLong(&hexValue) {
                switch (hex.characters.count) {
                case 3:
                    red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                    green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                    blue  = CGFloat(hexValue & 0x00F)              / 15.0
                case 4:
                    red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                    green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                    blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                    alpha = CGFloat(hexValue & 0x000F)             / 15.0
                case 6:
                    red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                    green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                    blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
                case 8:
                    red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                    green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                    blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                    alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
                default:
                    print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8")
                }
            } else {
                print("Scan hex error")
            }
        } else {
            print("Invalid RGB string, missing '#' as prefix")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}
