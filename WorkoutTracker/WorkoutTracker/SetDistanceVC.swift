//
//  SetDistanceVC.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 11/5/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import Parse
 
import MBProgressHUD

let DATE_ROW = 0
let DISTANCE_ROW = 1
let DURATION_ROW = 2

let COUNT_MIN = 59
let COUNT_HOUR = 23

let COUNT_KM = 200
let COUNT_M = 999

let MODE_DATE = 0
let MODE_DISTANCE = 1
let MODE_DURATION = 2

class SetDistanceVC: UIViewController {
    var progressHUD:MBProgressHUD!
    @IBOutlet var plusButton: UIButton!
    @IBOutlet var tableView: UITableView!
    var distancePicker:UIPickerView!
    var durationPicker:UIPickerView!
    var datePicker:UIDatePicker!
    
    var currentExercise:ExerciseTemplate!
    var data:NSDate?
    var idSet:String?
    var isNewSet:Bool!
    var setName:String!
    var selectedSet:ExerciseHistoryTemplate?
    var pfSetObject:PFObject?
    var workoutId:String?
    var isHistory:Bool!
    
    var mode:Int!//1 - Distance , 2 - Duration
    
    var indH:Int!
    var indKm:Int!
    var indMin:Int!
    var indM:Int!
    
    @IBOutlet var plusView: UIView!
    var distanceLabel: UILabel!
    var durationLabel: UILabel!
    var durationView: UIView!
    var distanceView: UIView!
    
    var typeDistance:String!
    var typeDurationLeft:String!
    var typeDurationRight:String!
    var typeDurationSec:String!
    var pickerValuesDistanceMode:[String]!
    var pickerValuesDurationMode = [
        ["00"],
        ["00"],
        ["00"]
    ]
    var selectedHours:String!
    var selectedMin:String!
    var selectedSec:String!
    var selectedDistance:String!
    var firstIndex:Int!
    var secondIndex:Int!
    var thirdIndex:Int!
    var dateLabel:UILabel!
    var lock:Bool!
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if(isHistory == true) {
            saveSet()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lock = false
         plusView.hidden = true
        if(isHistory != true) {
            let cancellButton = UIBarButtonItem(title: str_Cancel, style: UIBarButtonItemStyle.Done, target: self, action: "cancelButtonClick")
            
            self.navigationItem.leftBarButtonItem = cancellButton
        
            cancellButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16) ], forState: UIControlState.Normal)
            let DoneButton = UIBarButtonItem(title: str_Done, style: UIBarButtonItemStyle.Done, target: self, action: "doneButtonClick")
            
            self.navigationItem.rightBarButtonItem = DoneButton
        }
        mode = MODE_DISTANCE
        indH = 0
        indKm = 0
        indMin = 0
        indM = 0
        typeDistance = Settings.sharedInstance.currentDistanceUnit
        typeDurationLeft = str_hr
        typeDurationRight = str_min
        typeDurationSec = str_sec
        self.navigationItem.title = setName
        self.navigationController?.navigationBar.tintColor = UIColor(rgba: "#ff3e50ff")
        pickerValuesDistanceMode = [String]()
        pickerValuesDurationMode = [[String]]()
        initView()
        if(isNewSet == true) {
            self.navigationItem.title = str_NSet
        }
    }
    
    func updateSet() {
        let distanceStrs = self.distanceLabel.text?.characters.split{$0 == " "}.map(String.init)
        
        saveDef("\(distanceStrs![0]):\(self.typeDistance)",value2: self.durationLabel.text!)

        UserExercisesManager.sharedInstance.updateRecord((self.selectedSet?.sets![0].idSet)!, date: self.data!, leftValue: "\(distanceStrs![0]):\(self.typeDistance)", rightValue: self.durationLabel.text!)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func loadSetData() {
        let object = UserExercisesManager.sharedInstance.getSetById((selectedSet?.sets![0].idSet)!)
        self.pfSetObject = object!
        let distanceStr = self.pfSetObject?["leftValue"] as! String
        let durationStr = self.pfSetObject?["rightValue"] as! String
        let distanceValue = distanceStr.characters.split{$0 == ":"}.map(String.init)
        if(distanceValue[1] == str_km) {
            if(distanceValue[1] == self.typeDistance) {
                self.selectedDistance = distanceValue[0]
            }else {
                self.selectedDistance = Settings.sharedInstance.convertKmToMil(distanceValue[0], toMil: true)
            }
        }else {
            if(distanceValue[1] == self.typeDistance) {
                self.selectedDistance = distanceValue[0]
            }else {
                self.selectedDistance = Settings.sharedInstance.convertKmToMil(distanceValue[0], toMil: false)
            }
        }
        self.distanceLabel.text = "\(self.selectedDistance) \(self.typeDistance)"
        let distanceIndex = self.findPickerIndex(self.pickerValuesDistanceMode, value: self.selectedDistance,type: self.typeDistance)
        self.distancePicker.selectRow(distanceIndex, inComponent: 0, animated: true)
        let durationValue = durationStr.characters.split{$0 == ":"}.map(String.init)
        self.selectedHours = durationValue[0]
        self.selectedMin = durationValue[1]
        self.selectedSec = durationValue[2]
        
        let hourIndex = self.findPickerIndex(self.pickerValuesDurationMode[0], value: self.selectedHours ,type: self.typeDurationLeft)
        self.firstIndex = hourIndex
        if(self.durationPicker != nil) {
            self.durationPicker.selectRow(hourIndex, inComponent: 0, animated: true)
        }
        
        let minIndex = self.findPickerIndex(self.pickerValuesDurationMode[1], value: self.selectedMin,type: self.typeDurationRight)
        self.secondIndex = minIndex
        if(self.durationPicker != nil) {
            self.durationPicker.selectRow(minIndex, inComponent: 1, animated: true)
        }
        
        let secIndex = self.findPickerIndex(self.pickerValuesDurationMode[2], value: self.selectedSec,type: self.typeDurationSec)
        self.thirdIndex = secIndex
        if(self.durationPicker != nil) {
            self.durationPicker.selectRow(secIndex, inComponent: 2, animated: true)
        }
        self.durationLabel.text = "\(self.selectedHours):\(self.selectedMin):\(self.selectedSec)"
        
        
    }
    
    
    func findPickerIndex(array:[String],value:String,type:String) -> Int {
        
        for var i = 0;i < array.count ;i++ {
            var str = array[i].stringByReplacingOccurrencesOfString(type, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            str = str.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            let arrValue = Float(str)
            if(arrValue > Float(value)) {
                return i - 1
            }
        }
        var str = array[array.count - 1].stringByReplacingOccurrencesOfString(type, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        str = str.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let arrValue = Float(str)
        if(arrValue <= Float(value)) {
            return array.count - 1
        }
        return -1
    }
    func saveSet() {
        if(!isNewSet) {
            updateSet()
            return
        }
        let distanceStrs = self.distanceLabel.text?.characters.split{$0 == " "}.map(String.init)
        
        saveDef("\(distanceStrs![0]):\(self.typeDistance)",value2: self.durationLabel.text!)

        UserExercisesManager.sharedInstance.addRecord(currentExercise.id, date: data!, idWorkout: workoutId!, type: currentExercise.type, leftValue: "\(distanceStrs![0]):\(self.typeDistance)", rightValue: self.durationLabel.text!,onFinish: { () -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
    }
    func saveDef(value1:String,value2:String){
        let saveQ = PFQuery(className: "SettingStore")
        saveQ.fromLocalDatastore()
        saveQ.whereKey("id", equalTo: self.currentExercise.id)
        saveQ.findObjectsInBackgroundWithBlock({ (object , err ) -> Void in
            if(object?.count == 0) {
                let settingObject = PFObject(className: "SettingStore")
                settingObject["duration"] = value2
                settingObject["distance"] = value1
                settingObject.ownSaveEventually({ (bool , eror) -> Void in
                    settingObject["id"] = self.currentExercise.id
                    settingObject.pinInBackground()
                })
            }else {
                object?[0]["duration"] = value2
                object?[0]["distance"] = value1
                object?[0].pinInBackground()
            }
        })
    }
    
    func doneButtonClick() {
        if(lock == false) {
            saveSet()
            lock = true;
        }

    }
    
    func loadlocal(distanceStr:String,durationStr:String) {
        let distanceValue = distanceStr.characters.split{$0 == ":"}.map(String.init)
        if(distanceValue[1] == str_km) {
            if(distanceValue[1] == self.typeDistance) {
                self.selectedDistance = distanceValue[0]
            }else {
                self.selectedDistance = Settings.sharedInstance.convertKmToMil(distanceValue[0], toMil: true)
            }
        }else {
            if(distanceValue[1] == self.typeDistance) {
                self.selectedDistance = distanceValue[0]
            }else {
                self.selectedDistance = Settings.sharedInstance.convertKmToMil(distanceValue[0], toMil: false)
            }
        }
        self.distanceLabel.text = "\(self.selectedDistance) \(self.typeDistance)"
        let distanceIndex = self.findPickerIndex(self.pickerValuesDistanceMode, value: self.selectedDistance,type: self.typeDistance)
        self.distancePicker.selectRow(distanceIndex, inComponent: 0, animated: true)
        let durationValue = durationStr.characters.split{$0 == ":"}.map(String.init)
        self.selectedHours = durationValue[0]
        self.selectedMin = durationValue[1]
        self.selectedSec = durationValue[2]
        
        let hourIndex = self.findPickerIndex(self.pickerValuesDurationMode[0], value: self.selectedHours ,type: self.typeDurationLeft)
        self.firstIndex = hourIndex
        if(self.durationPicker != nil) {
            self.durationPicker.selectRow(hourIndex, inComponent: 0, animated: true)
        }
        
        let minIndex = self.findPickerIndex(self.pickerValuesDurationMode[1], value: self.selectedMin,type: self.typeDurationRight)
        self.secondIndex = minIndex
        if(self.durationPicker != nil) {
            self.durationPicker.selectRow(minIndex, inComponent: 1, animated: true)
        }
        
        let secIndex = self.findPickerIndex(self.pickerValuesDurationMode[2], value: self.selectedSec,type: self.typeDurationSec)
        self.thirdIndex = secIndex
        if(self.durationPicker != nil) {
            self.durationPicker.selectRow(secIndex, inComponent: 2, animated: true)
        }
        self.durationLabel.text = "\(self.selectedHours):\(self.selectedMin):\(self.selectedSec)"

    }
    
    func loadFromLocal() {
        let getDistanceValues = PFQuery(className: "SettingStore")
        getDistanceValues.fromLocalDatastore()
        getDistanceValues.whereKey("id", equalTo: currentExercise.id)
        getDistanceValues.findObjectsInBackgroundWithBlock { (object , error ) -> Void in
            if (object?.count != 0) {
                let distance = object?[0]["distance"] as? String
                let duration = object?[0]["duration"] as? String
                self.loadlocal(distance!, durationStr: duration!)
            }else {
                self.loadlocal("0:\(Settings.sharedInstance.currentDistanceUnit)", durationStr: "00:00:00")
            }
        }
            }
    func initView() {
        pickerValuesDistanceMode.removeAll()
        pickerValuesDistanceMode.append("0.00")
        pickerValuesDurationMode.removeAll()
        pickerValuesDurationMode.append(["0"])
        pickerValuesDurationMode.append(["0"])
        pickerValuesDurationMode.append(["0"])
        for var index = 0.25; index <= 50; index = index + 0.25 {
            pickerValuesDistanceMode.append(String(format: "%.2f", index))
        }
        for i in 0...pickerValuesDistanceMode.count - 1  {
            pickerValuesDistanceMode[i] = pickerValuesDistanceMode[i] + " " + typeDistance
        }
        
        for var index = 1; index <= COUNT_HOUR; index = index + 1 {
            pickerValuesDurationMode[0].append("\(index)")
        }
        for i in 0...pickerValuesDurationMode[0].count - 1  {
            pickerValuesDurationMode[0][i] = pickerValuesDurationMode[0][i] + " " + typeDurationLeft
        }
        var offs = 1
        for var index = 1; index <= COUNT_MIN; index = index + offs {
            if(index == 10) {
                offs = 5
            }
            pickerValuesDurationMode[1].append("\(index)")
        }
        
        for i in 0...pickerValuesDurationMode[1].count - 1  {
            pickerValuesDurationMode[1][i] = pickerValuesDurationMode[1][i] + " " + typeDurationRight
        }
        
        for var index = 1; index <= COUNT_MIN; index = index + 1 {
            pickerValuesDurationMode[2].append("\(index)")
        }
        for i in 0...pickerValuesDurationMode[2].count - 1  {
            pickerValuesDurationMode[2][i] = pickerValuesDurationMode[2][i] + " " + typeDurationSec
        }
    }
    
    func cancelButtonClick() {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    func changePickeres(insertIndex:Int,deleteIndex:Int,indexPath:NSIndexPath,insertAnimation:UITableViewRowAnimation,deleteAnim:UITableViewRowAnimation) {
        self.tableView.beginUpdates()
        
        let indexPatnInsert = NSIndexPath(forRow: indexPath.row + insertIndex, inSection: 0)
        let indexPathDelete = NSIndexPath(forRow: indexPath.row + deleteIndex, inSection: 0)
        self.tableView.deleteRowsAtIndexPaths([indexPathDelete], withRowAnimation: deleteAnim)
        self.tableView.insertRowsAtIndexPaths([indexPatnInsert], withRowAnimation: insertAnimation)
        
        self.tableView.endUpdates()
    }
}


extension SetDistanceVC : UITableViewDataSource,UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (mode == MODE_DATE) {
            if(indexPath.row == DISTANCE_ROW + 1) {
                mode = MODE_DISTANCE
                self.distancePicker = nil
                self.durationPicker = nil
                changePickeres(0, deleteIndex: -1,indexPath: indexPath,insertAnimation: UITableViewRowAnimation.Middle,deleteAnim: UITableViewRowAnimation.Middle)
                
                self.distanceLabel.textColor = UIColor(rgba: "#ff3e50ff")
                self.durationLabel.textColor = UIColor(rgba: "#898989ff")
                
            }else if(indexPath.row == DURATION_ROW + 1) {
                mode = MODE_DURATION
                self.distancePicker = nil
                self.durationPicker = nil
                
                changePickeres(0, deleteIndex: -2,indexPath: indexPath,insertAnimation: UITableViewRowAnimation.Top,deleteAnim: UITableViewRowAnimation.Middle)
                
                self.distanceLabel.textColor = UIColor(rgba: "#898989ff")
                self.durationLabel.textColor = UIColor(rgba: "#ff3e50ff")
                
            }
        }else  if (mode == MODE_DISTANCE) {
            if(indexPath.row == DATE_ROW) {
                mode = MODE_DATE
                self.distancePicker = nil
                self.durationPicker = nil
                changePickeres(1, deleteIndex: +2,indexPath: indexPath,insertAnimation: UITableViewRowAnimation.Middle,deleteAnim: UITableViewRowAnimation.Middle)
                
            }else if(indexPath.row == DURATION_ROW + 1) {
                mode = MODE_DURATION
                self.distancePicker = nil
                self.durationPicker = nil
                
                changePickeres(0, deleteIndex: -1,indexPath: indexPath,insertAnimation: UITableViewRowAnimation.Top,deleteAnim: UITableViewRowAnimation.Middle)
                
                self.distanceLabel.textColor = UIColor(rgba: "#898989ff")
                self.durationLabel.textColor = UIColor(rgba: "#ff3e50ff")
                
            }
        }else {
            if(indexPath.row == DATE_ROW) {
                mode = MODE_DATE
                self.distancePicker = nil
                self.durationPicker = nil
                changePickeres(1, deleteIndex: +3,indexPath: indexPath,insertAnimation: UITableViewRowAnimation.Middle,deleteAnim: UITableViewRowAnimation.Fade)
                
            }else if(indexPath.row == DISTANCE_ROW) {
                mode = MODE_DISTANCE
                self.distancePicker = nil
                self.durationPicker = nil
                
                changePickeres(+1, deleteIndex: +2,indexPath: indexPath,insertAnimation: UITableViewRowAnimation.Middle,deleteAnim: UITableViewRowAnimation.Fade)
                
                self.distanceLabel.textColor = UIColor(rgba: "#ff3e50ff")
                self.durationLabel.textColor = UIColor(rgba: "#898989ff")
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(mode == MODE_DATE) {
            if(indexPath.row == 1) {
                return 180
            }
        }else  if(mode == MODE_DISTANCE) {
            if (indexPath.row == 2) {
                return 180
            }
        }else {
            if(indexPath.row == 3) {
                return 180
            }
        }
        return 55
    }
    func dateChange() {
        if(self.datePicker.date.isGreaterThanDate(NSDate.today) == true)  {
            let sendMailErrorAlert = UIAlertView(title: str_InvalidDate, message: str_InvalidDateText, delegate: self, cancelButtonTitle: "OK")
            sendMailErrorAlert.show()
            self.datePicker.date = self.data!
            return
        }
        self.data! = self.datePicker.date
        if(self.data! == NSDate.today) {
            self.dateLabel.text = str_Today
        }else if(self.data! == NSDate.yesterdayMy()){
            self.dateLabel.text = str_Yesterday
        }else {
            self.dateLabel.text = NSDate.toString(self.data!)
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let extnCell = UITableViewCell()
        extnCell.textLabel?.text = "\(indexPath.row)"
        if(mode == MODE_DATE) {
            switch(indexPath.row) {
            case 0 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Date
                self.dateLabel = cell.rightLabel
                if(self.data == NSDate.today) {
                    self.dateLabel.text = str_Today
                }else if(self.data == NSDate.yesterdayMy()) {
                    self.dateLabel.text = str_Yesterday
                }else {
                    self.dateLabel.text = NSDate.toString(self.data!)
                }
                self.datePicker.setDate(data!, animated: false)
                return cell
            case 1 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailPickerTVC") as! SetDetailPickerTVC
                self.datePicker = cell.datePicker
                self.datePicker.hidden = false
                cell.pickerView.hidden = true
                cell.line.hidden = false
                cell.datePicker.setDate(self.data!, animated: false)
                cell.datePicker.minimumDate = NSDate.date("01.01.2010")
                cell.datePicker.maximumDate = NSDate.today
                cell.datePicker.addTarget(self, action: Selector("dateChange"), forControlEvents: UIControlEvents.ValueChanged)
                                  self.datePicker.setDate(data!, animated: false)
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Distance
                self.distanceLabel = cell.rightLabel
                self.distanceLabel.text = "0 \(self.typeDistance)"
                self.distanceLabel.textColor = UIColor(rgba: "#ff3e50ff")
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Duration
                self.durationLabel = cell.rightLabel
                self.durationLabel.text = "0 \(self.typeDurationLeft) 0 \(self.typeDurationRight) 0 \(self.typeDurationSec)"
                return cell
            default:
                break
            }

        }else if(mode == MODE_DISTANCE) {
            switch(indexPath.row) {
            case 0 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Date
                self.dateLabel = cell.rightLabel
                if(self.data == NSDate.today) {
                    self.dateLabel.text = str_Today
                }else if(self.data == NSDate.yesterdayMy()) {
                    self.dateLabel.text = str_Yesterday
                }else {
                    self.dateLabel.text = NSDate.toString(self.data!)
                }

                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Distance
                self.distanceLabel = cell.rightLabel
                self.distanceLabel.text = "0 \(self.typeDistance)"
                self.distanceLabel.textColor = UIColor(rgba: "#ff3e50ff")
                return cell
            case 2 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailPickerTVC") as! SetDetailPickerTVC
                distancePicker = cell.pickerView
                distancePicker.dataSource = self
                distancePicker.delegate = self
                distancePicker.hidden = false
                cell.datePicker.hidden = true
                cell.line.hidden = false
                return cell
            case 3:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Duration
                self.durationLabel = cell.rightLabel
                self.durationLabel.text = "0 \(self.typeDurationLeft) 0 \(self.typeDurationRight) 0 \(self.typeDurationSec)"
                if(isNewSet == true) {
                    loadFromLocal()
                }else {
                    loadSetData()
                }
                
                return cell
            default:
                break
            }

        }else {
            switch(indexPath.row) {
            case 0 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Date
                self.dateLabel = cell.rightLabel
                if(self.data == NSDate.today) {
                    self.dateLabel.text = str_Today
                }else if(self.data == NSDate.yesterdayMy()) {
                    self.dateLabel.text = str_Yesterday
                }else {
                    self.dateLabel.text = NSDate.toString(self.data!)
                }
                
                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Distance
                self.distanceLabel = cell.rightLabel
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Duration
                self.durationLabel = cell.rightLabel
                self.durationLabel.textColor = UIColor(rgba: "#ff3e50ff")
                return cell
            case 3 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailPickerTVC") as! SetDetailPickerTVC
                durationPicker = cell.pickerView
                durationPicker.dataSource = self
                durationPicker.delegate = self
                durationPicker.hidden = false
                cell.datePicker.hidden = true
                cell.line.hidden = true
                if(self.firstIndex != nil) {
                    durationPicker.selectRow(self.firstIndex, inComponent: 0, animated: true)
                    durationPicker.selectRow(self.secondIndex, inComponent: 1, animated: true)
                    durationPicker.selectRow(self.thirdIndex, inComponent: 2, animated: true)
                }
                return cell
            default:
                break
            }
        }
               return extnCell
    }
}
extension SetDistanceVC : UIPickerViewDataSource,UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(mode == MODE_DISTANCE) {
            let distance = pickerValuesDistanceMode[row]
            self.distanceLabel.text = "\(distance)"
        }else {
   
            if(component == 0) {
                let hour = pickerValuesDurationMode[0][row]
                self.selectedHours = hour
            }else if(component == 1) {
                let min = pickerValuesDurationMode[1][row]
                self.selectedMin = min
            }else {
                let sec = pickerValuesDurationMode[2][row]
                self.selectedSec = sec
                
            }
            
            self.selectedHours = self.selectedHours.stringByReplacingOccurrencesOfString(" " + typeDurationLeft, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            self.selectedMin = self.selectedMin.stringByReplacingOccurrencesOfString(" " + typeDurationRight, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            self.selectedSec = self.selectedSec.stringByReplacingOccurrencesOfString(" " + typeDurationSec, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            if(self.selectedHours.characters.count != 2) {
                self.selectedHours = "0\(self.selectedHours)"
            }
            if(self.selectedMin.characters.count != 2) {
                self.selectedMin = "0\(self.selectedMin)"
            }
            if(self.selectedSec.characters.count != 2) {
                self.selectedSec = "0\(self.selectedSec)"
            }
            self.durationLabel.text = "\(self.selectedHours):\(self.selectedMin):\(self.selectedSec)"
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(mode == MODE_DISTANCE) {
           return pickerValuesDistanceMode[row]
        }else {
           return pickerValuesDurationMode[component][row]
        }
        
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        if(mode == MODE_DISTANCE) {
            return 1
        }else {
            return 3
        }
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(mode == MODE_DISTANCE) {
            return pickerValuesDistanceMode.count
        }else {
            return pickerValuesDurationMode[component].count
        }
        
    }
    
    
    
    
}