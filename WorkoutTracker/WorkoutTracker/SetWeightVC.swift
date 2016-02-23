//
//  SetWeightVC.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 11/12/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import Parse
 

let COUNT_LB = 25
let COUNT = 300

class SetWeightVC: UIViewController {
    var currentExercise:ExerciseTemplate!
    var data:NSDate?
    var idSet:String?
    var isNewSet:Bool!
    var setName:String!
    var isHistory:Bool!
    var selectedSet:ExerciseHistoryTemplate?
    var pfSetObject:PFObject?
    var workoutId:String?
    var paramPicker: UIPickerView!
    var dateLabel: UILabel!
    var selectedParamLabel: UILabel!
    var setNameLabel: UILabel!
    var selectedWeight:String!
    var typeLeft:String!
    var typeRight:String!
    var mode:Bool!
    var datePicker:UIDatePicker!
    var isFirtsSetup:Bool!
    var lock:Bool!


    var pickerValues = [
        ["1"],
        ["0"]
    ]
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if(isHistory == true) {
            saveSet()
        }
        
    }
    
    @IBOutlet var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        lock = false
        //paramPicker.delegate = self
        //paramPicker.dataSource = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        mode = false
        isFirtsSetup = true
        if(isHistory != true) {
            let cancellButton = UIBarButtonItem(title: str_Cancel, style: UIBarButtonItemStyle.Done, target: self, action: "cancelButtonClick")
            
            self.navigationItem.leftBarButtonItem = cancellButton
            
            cancellButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16) ], forState: UIControlState.Normal)
            let DoneButton = UIBarButtonItem(title: str_Done, style: UIBarButtonItemStyle.Done, target: self, action: "doneButtonClick")
            
            self.navigationItem.rightBarButtonItem = DoneButton
        }
        
        typeLeft = str_reps
        typeRight = Settings.sharedInstance.currentWightUnit
        
        self.navigationItem.title = str_NSet
        
        self.navigationController?.navigationBar.tintColor = UIColor(rgba: "#ff3e50ff")
        
        for var index = 2; index <= COUNT; index++ {
            pickerValues[0].append("\(index)")
        }
        if(Settings.sharedInstance.currentWightUnit == str_lb) {
            var offs = 0.5
            for var index = 0.5; index <= Double(COUNT); index = index + offs {
                if(index == Double(COUNT_LB)) {
                    offs = 1
                }
                pickerValues[1].append("\(index)")
            }
        }else {
            for var index = 1; index <= COUNT; index++ {
                pickerValues[1].append("\(index)")
            }
        }
       
        
//        if(isNewSet == true) {
//            initView()
//            paramPicker.selectRow(0, inComponent: 0, animated: true)
//            paramPicker.selectRow(0, inComponent: 1, animated: true)
//            selectedParamLabel.text = "\(1) x \(1) \(self.typeRight)"
//        }else {
//            //loadSetData()
//        }

        
    }
    
    func initView() {
        if( NSLocale.preferredLanguages()[0] == "ru") {
            for i in 0...pickerValues[0].count - 1  {
                if((((i + 1) > 10 && (i + 1) < 20))) {
                    pickerValues[0][i] = pickerValues[0][i] + " " + typeLeft
                    continue
                }
                if(((i + 1)  % 10) == 2)||(((i + 1) % 10) == 3)||(((i + 1) % 10) == 4 ) {
                    pickerValues[0][i] = pickerValues[0][i] + " " + typeLeft + "а"
                    continue
                }
                pickerValues[0][i] = pickerValues[0][i] + " " + typeLeft
            }
        }else {
            pickerValues[0][0] = pickerValues[0][0] + " " + typeLeft.stringByReplacingOccurrencesOfString("s", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            for i in 1...pickerValues[0].count - 1  {
                pickerValues[0][i] = pickerValues[0][i] + " " + typeLeft
            }
            
        }
        for i in 0...pickerValues[1].count - 1 {
            if(i == 0) {
                pickerValues[1][i] = str_NoWeight;
                continue
            }
            pickerValues[1][i] = pickerValues[1][i] + " " + typeRight
        }
        setNameLabel.text = setName
    }
    
    func loadSetData() {
        let object = UserExercisesManager.sharedInstance.getSetById((selectedSet?.sets![0].idSet)!)
        if(object == nil) {
            return
        }
        self.pfSetObject = object!
        let date = self.selectedSet?.date
        if(date == NSDate.today) {
            self.dateLabel.text = str_Today
        }else if(date == NSDate.yesterdayMy()){
            self.dateLabel.text = str_Yesterday
        }else {
            self.dateLabel.text = NSDate.toString(self.selectedSet!.date!)
        }
        let leftValue = self.pfSetObject?["leftValue"] as! String
        let rightValue = self.pfSetObject?["rightValue"] as! String
        let weightValue = rightValue.characters.split{$0 == ":"}.map(String.init)
        if(weightValue[1] == str_kg) {
            if(weightValue[1] == self.typeRight) {
                self.selectedWeight = weightValue[0]
            }else {
                self.selectedWeight = Settings.sharedInstance.convertKgToPd(weightValue[0], toPd: true)
            }
        }else {
            if(weightValue[1] == self.typeRight) {
                self.selectedWeight = weightValue[0]
            }else {
                self.selectedWeight = Settings.sharedInstance.convertKgToPd(weightValue[0], toPd: false)
            }
        }
        let weightIndex = self.findPickerIndex(self.pickerValues[1], value: self.selectedWeight,type: self.typeRight)
        self.paramPicker.selectRow(self.pickerValues[0].indexOf(){ $0 == leftValue }!, inComponent: 0, animated: false)
        self.paramPicker.selectRow(weightIndex, inComponent: 1, animated: false)
        self.selectedParamLabel.text = "\(leftValue) x \(self.selectedWeight) \(self.typeRight)"
        self.initView()
        self.navigationItem.title = self.setName
        self.paramPicker.reloadAllComponents()
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
    
    func cancelButtonClick() {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func saveDate(){
        let updateDateFromHistoryStore = PFQuery(className: HISTORY_STORE)
        updateDateFromHistoryStore.fromLocalDatastore()
        updateDateFromHistoryStore.whereKey("id", equalTo: (self.selectedSet?.idHistory)!)
        updateDateFromHistoryStore.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
            if(objects?.count != 0) {
                objects?[0]["date"] = NSDate.toString(self.data!)
                objects?[0].pinInBackground()
            }
        }
        
    }
    
    func updateSet() {
        var value =  self.selectedParamLabel.text!.characters.split{$0 == "x"}.map(String.init)
        value[0] = value[0].stringByReplacingOccurrencesOfString(self.typeLeft, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[0] = value[0].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[1] = value[1].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[1] = value[1].stringByReplacingOccurrencesOfString(self.typeRight, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)

        UserExercisesManager.sharedInstance.updateRecord((self.selectedSet?.sets![0].idSet)!, date: self.data!, leftValue: value[0], rightValue: "\(value[1]):\(self.typeRight)")
        
        
        saveDef(value[0],value2: "\(value[1]):\(self.typeRight)")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func saveDef(value1:String,value2:String){
        let saveQ = PFQuery(className: "SettingStore")
        saveQ.fromLocalDatastore()
        saveQ.whereKey("id", equalTo: self.currentExercise.id)
        saveQ.findObjectsInBackgroundWithBlock({ (object , err ) -> Void in
            if(object?.count == 0) {
                let settingObject = PFObject(className: "SettingStore")
                settingObject["reps"] = value1
                settingObject["weight"] = "\(value2):\(self.typeRight)"
                settingObject.ownSaveEventually({ (bool , eror) -> Void in
                    settingObject["id"] = self.currentExercise.id
                    settingObject.pinInBackground()
                    
                })
            }else {
                object?[0]["reps"] = value1
                object?[0]["weight"] = "\(value2):\(self.typeRight)"
                object?[0].pinInBackground()
                
                
            }
        })

    }
    func saveSet() {
        if(!isNewSet) {
            updateSet()
            return
        }
        var value =  self.selectedParamLabel.text!.characters.split{$0 == "x"}.map(String.init)
        value[0] = value[0].stringByReplacingOccurrencesOfString(self.typeLeft, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[0] = value[0].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[1] = value[1].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[1] = value[1].stringByReplacingOccurrencesOfString(self.typeRight, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        saveDef(value[0],value2: "\(value[1]):\(self.typeRight)")
        UserExercisesManager.sharedInstance.addRecord(currentExercise.id, date: data!, idWorkout: workoutId!, type: currentExercise.type, leftValue: value[0], rightValue: "\(value[1]):\(self.typeRight)",onFinish: { () -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        })       
        
    }
    
    func loadlocal(leftValue:String,rightValue:String) {
        let weightValue = rightValue.characters.split{$0 == ":"}.map(String.init)
        if(weightValue[1] == str_kg) {
            if(weightValue[1] == self.typeRight) {
                self.selectedWeight = weightValue[0]
            }else {
                self.selectedWeight = Settings.sharedInstance.convertKgToPd(weightValue[0], toPd: true)
            }
        }else {
            if(weightValue[1] == self.typeRight) {
                self.selectedWeight = weightValue[0]
            }else {
                self.selectedWeight = Settings.sharedInstance.convertKgToPd(weightValue[0], toPd: false)
            }
        }
        let weightIndex = self.findPickerIndex(self.pickerValues[1], value: self.selectedWeight,type: self.typeRight)
        self.paramPicker.selectRow(self.pickerValues[0].indexOf(){ $0 == leftValue }!, inComponent: 0, animated: false)
        self.paramPicker.selectRow(weightIndex, inComponent: 1, animated: false)
        self.selectedParamLabel.text = "\(leftValue) x \(self.selectedWeight) \(self.typeRight)"
        self.initView()
        self.navigationItem.title = self.setName
        self.paramPicker.reloadAllComponents()
    }
    
    func loadFromLocal() {
        let getDistanceValues = PFQuery(className: "SettingStore")
        getDistanceValues.fromLocalDatastore()
        getDistanceValues.whereKey("id", equalTo: currentExercise.id)
        getDistanceValues.findObjectsInBackgroundWithBlock { (object , error ) -> Void in
            if (object?.count != 0) {
                let reps = object?[0]["reps"] as? String
                let weight = object?[0]["weight"] as? String
                self.loadlocal(reps!, rightValue: weight!)
            }else {
                self.loadlocal("1", rightValue: "0:km")
            }
        }
    }
    

    func doneButtonClick() {
        if(lock == false) {
            saveSet()
            lock = true;
        }
        
    }
    func backToHistory() {
        saveSet()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension SetWeightVC : UITableViewDataSource,UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(mode == true) {
             if(indexPath.row == 2) {
                mode = false
                self.tableView.beginUpdates()
                
                let indexPathDelete = NSIndexPath(forRow: indexPath.row - 1, inSection: 0)
                let indexPathInsert = NSIndexPath(forRow: indexPath.row, inSection: 0)
                
                self.tableView.deleteRowsAtIndexPaths([indexPathDelete], withRowAnimation: UITableViewRowAnimation.Middle)
                self.tableView.insertRowsAtIndexPaths([indexPathInsert], withRowAnimation: UITableViewRowAnimation.Top)
                
                self.tableView.endUpdates()
            }
            
        }else {
            if(indexPath.row == 0) {
                mode = true
                self.tableView.beginUpdates()
                
                let indexPathDelete = NSIndexPath(forRow: indexPath.row + 2, inSection: 0)
                let indexPathInsert = NSIndexPath(forRow: indexPath.row + 1, inSection: 0)
                
                self.tableView.deleteRowsAtIndexPaths([indexPathDelete], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.insertRowsAtIndexPaths([indexPathInsert], withRowAnimation: UITableViewRowAnimation.Middle)
                
                self.tableView.endUpdates()
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(mode == true) {
            if (indexPath.row == 1) {
                return 180
            }else if (indexPath.row == 3){
                return 180
            }
        }else {
            if (indexPath.row == 2) {
                return 180
            }
        }
        return 55
    }
    
    func dateChange() {
        if(self.datePicker.date.isGreaterThanDate(NSDate.today) == true) {
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
        if(mode == true) {
            switch(indexPath.row) {
            case 0 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Date
                self.dateLabel = cell.rightLabel
                if(self.data! == NSDate.today) {
                    self.dateLabel.text = str_Today
                }else if(self.data! == NSDate.yesterdayMy()){
                    self.dateLabel.text = str_Yesterday
                }else {
                    self.dateLabel.text = NSDate.toString(self.data!)
                }

                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailPickerTVC") as! SetDetailPickerTVC
                self.datePicker = cell.datePicker
                self.datePicker.hidden = false
                cell.pickerView.hidden = true
                cell.line.hidden = false
                cell.datePicker.setDate(self.data!, animated: false)
                cell.datePicker.addTarget(self, action: Selector("dateChange"), forControlEvents: UIControlEvents.ValueChanged)
                self.datePicker.setDate(data!, animated: false)
                cell.datePicker.minimumDate = NSDate.date("01.01.2010")
                cell.datePicker.maximumDate = NSDate.today
                cell.line.hidden = false
                return cell
            case 2:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = str_Duration
                self.setNameLabel = cell.leftLabel
                self.selectedParamLabel = cell.rightLabel
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
                if(self.data! == NSDate.today) {
                    self.dateLabel.text = str_Today
                }else if(self.data! == NSDate.yesterdayMy()){
                    self.dateLabel.text = str_Yesterday
                }else {
                    self.dateLabel.text = NSDate.toString(self.data!)
                }

                return cell
            case 1:
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailTVC") as! SetDetailTVC
                cell.leftLabel.text = self.setName
                self.setNameLabel = cell.leftLabel
                self.selectedParamLabel = cell.rightLabel
                self.selectedParamLabel.text = "\(1) x \(1) \(self.typeRight)"
                
                return cell
            case 2 :
                let cell = tableView.dequeueReusableCellWithIdentifier("SetDetailPickerTVC") as! SetDetailPickerTVC
                self.paramPicker = cell.pickerView
                self.paramPicker.delegate = self
                self.paramPicker.dataSource = self
                cell.line.hidden = true
                if(self.isFirtsSetup == true) {
                    if(isNewSet == true) {
                        //initView()
//                        paramPicker.selectRow(0, inComponent: 0, animated: true)
//                        paramPicker.selectRow(0, inComponent: 1, animated: true)
//                        selectedParamLabel.text = "\(1) x \(1) \(self.typeRight)"
                        loadFromLocal()
                    }else {
                        self.loadSetData()
                       
                    }
                    self.isFirtsSetup = false
                    
                    
                }
                return cell
            default:
                break
            }
        }
        return extnCell
    }
}


extension SetWeightVC:UIPickerViewDataSource,UIPickerViewDelegate {
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerValues[component].count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerValues[component][row]
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var value =  selectedParamLabel.text!.characters.split{$0 == "x"}.map(String.init)
        if(component == 0) {
            value[0] = pickerValues[component][row]
        }else {
            value[1] = pickerValues[component][row]
        }
        if(component == 1 && row == 0) {
            value[1] = "\(0)"
        }
        
        value[0] = value[0].stringByReplacingOccurrencesOfString(typeLeft, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[0] = value[0].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[1] = value[1].stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        value[1] = value[1].stringByReplacingOccurrencesOfString(typeRight, withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        if( NSLocale.preferredLanguages()[0] == "ru") {
            value[0] = value[0].stringByReplacingOccurrencesOfString("а", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        }else {
            value[0] = value[0].stringByReplacingOccurrencesOfString("s", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
        selectedParamLabel.text = "\(value[0]) x \(value[1]) \(typeRight)"
    }

}
