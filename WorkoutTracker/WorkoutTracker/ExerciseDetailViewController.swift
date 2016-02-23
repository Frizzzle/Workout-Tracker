
//
//  ExerciseDetailViewController.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/21/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit

import Parse
import MBProgressHUD
import Darwin

let HISTORY_STORE = "History"
let HISTORY_AUXILIARY = "HistoryAuxiliary"
let HISTORY_SETS = "HistorySets"
class ExerciseDetailViewController: UIViewController {
    var transportExercises:[ExerciseTemplate]!
    var transportExercise: ExerciseTemplate!
    var transportIndex:Int!
    var exercises:[ExerciseHistoryTemplate]!
    var lastItemId:String!
    var countDate:Int!
    var workoutId:String!
    @IBOutlet var bestDateLabel: UILabel!
    @IBOutlet var bestValueLabel: UILabel!
    var supportTextField:UITextField!
    var countExercise:Int!
    var sortedSets:[String : [ExerciseHistoryTemplate!]]!
    var progressHUD:MBProgressHUD!
    var bestValue:String!
    var sortedDate:[String]!
    var bestDate:String!
    var type:String!
    var countQuery:Int!
    var globalCount:Int!
    var coefDistance:Double!
    var coefWeight:Double!
    var bestDistance:Double!
    var bestHour:Int!
    var bestMin:Int!
    var bestSec:Int!
    var isEmpty:Bool!
    var selectedIndex:Int!
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    var selectedElement:ExerciseHistoryTemplate!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var emptyScreenView: UIView!
    var progressBar:MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        if(UserExercisesManager.sharedInstance.isExerciseEmpty(transportExercises[transportIndex].id)){
            self.emptyScreenView.hidden = false
        }else {
            self.emptyScreenView.hidden = true
        }
        if(transportExercises.count == 1) {
            nextBtn.hidden = true
            prevBtn.hidden = true
        }
        
        initData()
        if(transportIndex == 0) {
            prevBtn.hidden = true
        }else if(transportIndex == self.transportExercises.count - 1) {
            nextBtn.hidden = true
        }
        let editButton = UIBarButtonItem(title: str_Edit, style: UIBarButtonItemStyle.Done, target: self, action: "editButtonClick")
        
        editButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16) ], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = editButton
    }
    
    func showRenameDialog(){
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .Alert)
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
        let gString = NSMutableAttributedString(string:"\(str_Rename) \(transportExercises[transportIndex].name) \(str_exercise)", attributes:attrs)
        actionSheetController.setValue(gString, forKey: "attributedTitle")
        let cancelAction: UIAlertAction = UIAlertAction(title: str_Cancel, style: .Default) { action -> Void in
            self.supportTextField = nil
        }
        actionSheetController.addAction(cancelAction)
        
        let renameAction: UIAlertAction = UIAlertAction(title: str_Rename, style: .Default) { action -> Void in
            
            if(self.supportTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty == true) {
                let nameEmptyAlert: UIAlertController = UIAlertController(title: "", message: str_PlsInpExerName, preferredStyle: .Alert)
                let cancelAction = UIAlertAction(title: str_Close, style: .Cancel) { action -> Void in
                    self.showRenameDialog()
                }
                nameEmptyAlert.addAction(cancelAction)
                self.presentViewController(nameEmptyAlert, animated: true, completion: nil)
                return
            }else {
                if(!self.isUnic(self.supportTextField.text!) && (self.supportTextField.text != self.transportExercises[self.transportIndex].name)) {
                    let nameExistAlert: UIAlertController = UIAlertController(title: "", message: str_ExExistName, preferredStyle: .Alert)
                    let cancelAction = UIAlertAction(title: str_Close, style: .Cancel, handler: {(alert: UIAlertAction!) in
                        self.showRenameDialog()
                    })
                    nameExistAlert.addAction(cancelAction)
                    self.presentViewController(nameExistAlert, animated: true, completion: nil)
                    
                    return
                }
            }
            self.transportExercises[self.transportIndex].name = self.supportTextField.text!
            self.renameInStore(self.supportTextField.text!)
            self.navigationItem.title = self.transportExercises[self.transportIndex].name
        }
        
        actionSheetController.addAction(renameAction)
        
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            
            textField.text = self.transportExercises[self.transportIndex].name
            self.supportTextField = textField
        }
        
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    func renameInStore(name:String) {
        ExerciseManager.sharedInstance.renameExercise(name,id: self.transportExercises[self.transportIndex].id)
    }
    
    func isUnic(name:String) -> Bool {
        return ExerciseManager.sharedInstance.isUnicName(name)
    }
    
    func showClearingDialog() {
        var actionSheetController: UIAlertController = UIAlertController(title: "\(str_Clear) \(self.transportExercises[self.transportIndex].name) \(str_History)", message: str_ClrHistory, preferredStyle: .Alert)
        if( NSLocale.preferredLanguages()[0] == "ru") {
            actionSheetController = UIAlertController(title: "\(str_ClrHistoryL)", message: str_ClrHistory, preferredStyle: .Alert)
        }
        
        let attrs = [NSFontAttributeName : UIFont.systemFontOfSize(15)]
        let gString = NSMutableAttributedString(string:str_ClrHistory, attributes:attrs)
        actionSheetController.setValue(gString, forKey: "attributedMessage")
        
        
        let deleteAction: UIAlertAction = UIAlertAction(title: str_Clear, style: .Default) { action -> Void in
            
            self.clear()
        }
        actionSheetController.addAction(deleteAction)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: str_Cancel, style: .Default) { action -> Void in
        }
        actionSheetController.addAction(cancelAction)
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
        
    }
    
    func clear() {
        UserExercisesManager.sharedInstance.deleteExerciseHistory(self.transportExercises[self.transportIndex].id) { () -> Void in
            self.emptyScreenView.hidden = false
            self.exercises.removeAll()
            self.sortedSets.removeAll()
            self.sortedDate.removeAll()
            self.tableView.reloadData()
        }
    }
    func editButtonClick(){
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let renameAction = UIAlertAction(title: str_RnmEx, style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showRenameDialog()
        })
        let deleteAction = UIAlertAction(title: str_ClrHistoryL, style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.showClearingDialog()
        })
        let cancelAction = UIAlertAction(title: str_Cancel, style: .Cancel, handler: nil)
        optionMenu.addAction(renameAction)
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(cancelAction)
        self.presentViewController(optionMenu, animated: true, completion: nil)
    }
    
    func initData() {
        self.navigationItem.title = transportExercises[transportIndex].name
        countDate = 1
        self.exercises = [ExerciseHistoryTemplate]()
        self.sortedSets = [String : [ExerciseHistoryTemplate!]]!()
        if(Settings.sharedInstance.currentWightUnit == str_kg) {
            coefWeight = 1
        }else {
            coefWeight = 2.20462
        }
        if(Settings.sharedInstance.currentDistanceUnit == str_km) {
            coefDistance = 1
        }else {
            coefDistance = 1.6
        }
        type = transportExercises[transportIndex].type == "Weight" ?Settings.sharedInstance.currentWightUnit: Settings.sharedInstance.currentDistanceUnit
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "setDetailWeight") {
            let setupSetNC = segue.destinationViewController as! UINavigationController
            let setupSetVC = setupSetNC.viewControllers.first as! SetWeightVC
            setupSetVC.data = NSDate.today
            setupSetVC.isHistory = false
            setupSetVC.currentExercise = transportExercises[transportIndex]
            if(self.selectedElement == nil) {
                setupSetVC.isNewSet = true
                setupSetVC.workoutId = self.workoutId
                var str = ""
                str = NSDate.toString(NSDate.today)
                
                if(sortedSets == nil) {
                    setupSetVC.setName = "\(str_Set) 1"
                } else {
                    if (sortedSets[str] != nil) {
                        
                        let temp = sortedSets[NSDate.toString(NSDate.today)]!.count
                        setupSetVC.setName = "\(str_Set) \(temp + 1)"
                        
                    }else {
                        setupSetVC.setName = "\(str_Set) 1"
                    }
                }
                
                
            }else {
                setupSetVC.data = self.selectedElement.date
                setupSetVC.isNewSet = false
                setupSetVC.selectedSet = self.selectedElement
                setupSetVC.setName = "\(str_Set) \(self.selectedIndex + 1)"
            }
        }else {
            let setupSetNC = segue.destinationViewController as! UINavigationController
            let setupSetVC = setupSetNC.viewControllers.first as! SetDistanceVC
            setupSetVC.isHistory = false
            setupSetVC.data = NSDate.today
            setupSetVC.currentExercise = transportExercises[transportIndex]
            if(self.selectedElement == nil) {
                setupSetVC.isNewSet = true
                setupSetVC.workoutId = self.workoutId
                var str = ""
                str = NSDate.toString(NSDate.today)
                
                if(sortedSets == nil) {
                    setupSetVC.setName = "\(str_Set) 1"
                } else {
                    if (sortedSets[str] != nil) {
                        let temp = sortedSets[NSDate.toString(NSDate.today)]!.count
                        setupSetVC.setName = "\(str_Set) \(temp + 1)"
                        
                    }else {
                        setupSetVC.setName = "\(str_Set) 1"
                    }
                }
                
                
            }else {
                setupSetVC.data = self.selectedElement.date
                setupSetVC.isNewSet = false
                setupSetVC.selectedSet = self.selectedElement
                setupSetVC.setName = "\(str_Set) \(self.selectedIndex + 1)"
            }
            
        }
    }
    
    @IBAction func previousTouch(sender: AnyObject) {
        self.selectedElement = nil
        transportIndex = transportIndex - 1
        if(transportIndex <= 0) {
            prevBtn.hidden = true
            transportIndex = 0
        }else {
            prevBtn.hidden = false
        }
        nextBtn.hidden = false
        initData()
        getExercises()
        self.tableView.reloadData()
    }
    @IBAction func plusTouch(sender: AnyObject) {
        if(transportExercises[transportIndex].type == "Weight") {
            performSegueWithIdentifier("setDetailWeight", sender: self)
        }else {
            performSegueWithIdentifier("setDetailDistance", sender: self)
        }
    }
    @IBAction func nextTouch(sender: AnyObject) {
        self.selectedElement = nil
        transportIndex = transportIndex + 1
        if(transportIndex >= self.transportExercises.count - 1) {
            nextBtn.hidden = true
            transportIndex = self.transportExercises.count - 1
        }else {
            nextBtn.hidden = false
            
        }
        prevBtn.hidden = false
        
        initData()
        getExercises()
    }
    
    func getExercises() {
        bestValue = "-1"
        bestDistance = 0
        bestHour = 25
        bestMin  = 60
        bestSec = 60
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            UserExercisesManager.sharedInstance.getExerciseHistory(self.transportExercises[self.transportIndex].id,     onSuccess: { (result) -> Void in
                self.exercises = result
                self.getBest()
                self.sortSetsForData()
                dispatch_async(dispatch_get_main_queue()) {
                    self.bestDateLabel.text = "\(str_BestR) (\(self.bestDate))"
                    self.emptyScreenView.hidden = true
                    self.tableView.reloadData()
                }
            })

        }
        
    }
    
    func getBest() {
        bestValue = "-1"
        bestDistance = 0
        bestHour = 25
        bestMin  = 60
        bestSec = 60
        for item in self.exercises {
            self.isBest((item.sets?[0].rightValue)!, leftValue: (item.sets?[0].leftValue)!, date: NSDate.toString(item.date!))
        }
        if(self.transportExercises[self.transportIndex].type == "Weight") {
            self.bestValueLabel.text = self.bestValue + " " + self.type
        }else {
            
            let hour = self.bestHour < 10 ? "0\(self.bestHour)" : "\(self.bestHour)"
            let min = self.bestMin < 10 ? "0\(self.bestMin)" : "\(self.bestMin)"
            let sec = self.bestSec < 10 ? "0\(self.bestSec)" : "\(self.bestSec)"
            self.bestValueLabel.text =  "\(self.bestDistance) \(Settings.sharedInstance.currentDistanceUnit), \(hour):\(min):\(sec)"
        }
    }
    
    func isBest(rightValue:String,leftValue:String,date: String) {
        if(transportExercises[transportIndex].type == "Weight") {
            let value =  rightValue.characters.split{$0 == ":"}.map(String.init)
            let weightStr:String!
            if(value[1] == str_kg) {
                if(value[1] == Settings.sharedInstance.currentWightUnit) {
                    weightStr = value[0]
                }else {
                    weightStr = Settings.sharedInstance.convertKgToPd(value[0], toPd: true)
                }
            }else {
                if(value[1] == Settings.sharedInstance.currentWightUnit) {
                    weightStr = value[0]
                }else {
                    weightStr = Settings.sharedInstance.convertKgToPd(value[0], toPd: false)
                }
            }
            if(Double(weightStr) > Double(self.bestValue)! ) {
                
                self.bestValue = weightStr
                
                self.bestDate = date
                
            }
        }else {
            let distance =  leftValue.characters.split{$0 == ":"}.map(String.init)
            let distanceStr:String!
            if(distance[1] == str_km) {
                if(distance[1] == Settings.sharedInstance.currentDistanceUnit) {
                    distanceStr = distance[0]
                }else {
                    distanceStr = Settings.sharedInstance.convertKmToMil(distance[0], toMil: true)
                }
            }else {
                if(distance[1] == Settings.sharedInstance.currentDistanceUnit) {
                    distanceStr = distance[0]
                }else {
                    distanceStr = Settings.sharedInstance.convertKmToMil(distance[0], toMil: false)
                }
            }
            if(self.bestDistance <= Double(distanceStr)) {
                let time =  rightValue.characters.split{$0 == ":"}.map(String.init)
                if(Int(time[0]) <= self.bestHour ) {
                    if(Int(time[1]) <= self.bestMin ) {
                        if(Int(time[2]) <= self.bestSec ) {
                            self.bestDistance = Double(distanceStr)
                            self.bestHour = Int(time[0])
                            self.bestMin = Int(time[1])
                            self.bestSec = Int(time[2])
                            self.bestDate = date
                        }
                    }
                    
                }
            }
        }
        
    }
    func sortSetsForData() {
        self.sortedDate = [String] ()
        sortedSets = [String : [ExerciseHistoryTemplate!]]()
        for exercise in self.exercises {
            let key = NSDate.toString(exercise.date!)
            if let _ = sortedSets[key] {
                sortedSets[key]?.append(exercise)
            }else {
                sortedSets[key] = [ExerciseHistoryTemplate]()
                self.sortedAppend(key)
                //self.sortedDate.append(key!)
                sortedSets[key]?.append(exercise)
            }
        }
        
    }
    
    func sortedAppend(key:String) {
        for var i = 0; i < self.sortedDate.count; i = i + 1 {
            if(NSDate.date(self.sortedDate[i]).isLessThanDate(NSDate.date(key)) == true) {
                self.sortedDate.insert(key, atIndex: i)
                return
            }
        }
        self.sortedDate.append(key)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.exercises.removeAll()
        self.selectedElement = nil
        self.getExercises()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func deleteExercise(idRecord:String,indexPath:Int,key:String) {
        UserExercisesManager.sharedInstance.deleteExercise(idRecord) { () -> Void in
            for var i = 0; i < self.exercises.count;i++ {
                if(self.exercises[i].sets?[0].idSet == idRecord) {
                    self.exercises.removeAtIndex(i)
                    break;
                }
            }
            if(self.exercises.count != 0) {
                self.getBest()
            }
            
            if(self.sortedSets.count == 0) {
                return
            }
            if(self.sortedSets[key]?.count == 1) {
                self.sortedSets.removeValueForKey(key)
                self.sortedDate.removeAtIndex(self.sortedDate.indexOf() {$0 == key}!)
            }else {
                for var i = 0;i < self.sortedSets[key]?.count;i++ {
                    if(self.sortedSets[key]?[i].sets![0].idSet == idRecord) {
                        self.sortedSets[key]?.removeAtIndex(i)
                        break;
                    }
                }
            }
            self.tableView.reloadData()
        }
    }
    
}


extension ExerciseDetailViewController : UITableViewDataSource,UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(self.sortedSets == nil) {
            return
        }
        let key = getKey(indexPath.section)
        selectedElement = self.sortedSets[key]?[indexPath.row]
        selectedIndex = indexPath.row
        if(transportExercises[transportIndex].type == "Weight")  {
            performSegueWithIdentifier("setDetailWeight", sender: self)
        }else {
            performSegueWithIdentifier("setDetailDistance", sender: self)
        }
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            if(self.sortedSets == nil) {
                return
            }
            let key = getKey(indexPath.section)
            self.deleteExercise((self.sortedSets[key]?[indexPath.row]!.sets?[0].idSet)!, indexPath: indexPath.row, key: key)
            //self.removeObjectFromTables((self.sortedSets[key]?[indexPath.row]!.idExercise)!,idSet: (self.sortedSets[key]?[indexPath.row]!.sets?[0].idSet)!,key: key,indexPath: indexPath.row)
            
            break
        default :
            break
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if(self.sortedSets == nil) {
            return 0
        }
        if(self.sortedSets.count == 0) {
            emptyScreenView.hidden = false
        }
        return self.sortedSets.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.sortedSets == nil) {
            return 0
        }
        let key = getKey(section) // index 1
        if(self.sortedSets[key] == nil) {
            return 0
        }
        return (self.sortedSets[key]?.count)!
    }
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 0.94 , green: 0.94, blue: 0.94, alpha: 1);
        
        // if you have index/header text in your tableview change your index text color
        let headerIndexText = view as! UITableViewHeaderFooterView
        if(headerIndexText.textLabel?.text == str_Today) {
            headerIndexText.textLabel?.textColor = UIColor(rgba: "#ff4051")
        }else {
            headerIndexText.textLabel?.textColor = UIColor(rgba: "#000000")
        }
        
        //headerIndexText.textLabel?.font =  UIFont(name: "SanFranciscoText-Medium", size: 17)
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //        let date = NSDate()
        //        let calendar = NSCalendar.currentCalendar()
        //        let components = calendar.component([NSCalendarUnit.Month  , NSCalendarUnit.Day], fromDate: date)
        let date:NSDate
        if(self.sortedSets == nil) {
            return ""
        }
        let key = getKey(section)
        date = NSDate.date(key)
        
        if(date == NSDate.today) {
            return str_Today
        }else if(date == NSDate.yesterdayMy()){
            return str_Yesterday
        }
        var weekDayName  = ""
        switch(date.weekday) {
        case 0 :
            weekDayName = str_Saturday
            break
        case 1:
            weekDayName = str_Sunday
            break
        case 2:
            weekDayName = str_Monday
            break
        case 3:
            weekDayName = str_Tuesday
            break
        case 4:
            weekDayName = str_Wednesday
            break
        case 5:
            weekDayName = str_Thursday
            break
        case 6:
            weekDayName = str_Friday
            break
        case 7:
            weekDayName = str_Saturday
            break
        default :
            break
        }
        let dateString = weekDayName + ", " + NSDate.toString(date)
        
        return dateString
    }
    func getKey(indexPath:Int) -> String {
        
        //let intIndex = indexPath // where intIndex < myDictionary.count
        //let index = self.sortedSets.startIndex.advancedBy(intIndex)
        
        return self.sortedDate[indexPath]
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ExerciseDetailCell") as! ExerciseDetailCell
        if(self.sortedSets.count == 0) {
            return cell
        }
        cell.setName.text = "\(str_Set) \(indexPath.row + 1)"
        if(self.sortedSets == nil) {
            return cell
        }
        let key = getKey(indexPath.section)
        
        if(transportExercises[transportIndex].type != "Weight") {
            if(self.sortedSets[key]![indexPath.row]!.sets == nil) {
                return cell
            }
            let timeValue = self.sortedSets[key]![indexPath.row]!.sets![0].rightValue!.characters.split{$0 == ":"}.map(String.init)
            var timeStr = "\(timeValue[0]):\(timeValue[1]):\(timeValue[2])"
            
            if((timeValue[0] == "00") && (timeValue[1] == "00") && (timeValue[2] == "00") ) {
                timeStr = ""
            }
            
            let distanceValue = self.sortedSets[key]![indexPath.row]!.sets![0].leftValue!.characters.split{$0 == ":"}.map(String.init)
            let distance:String!
            if(distanceValue[1] == str_km) {
                if(distanceValue[1] == Settings.sharedInstance.currentDistanceUnit) {
                    distance = distanceValue[0]
                }else {
                    distance = Settings.sharedInstance.convertKmToMil(distanceValue[0], toMil: true)
                }
            }else {
                if(distanceValue[1] == Settings.sharedInstance.currentDistanceUnit) {
                    distance = distanceValue[0]
                }else {
                    distance = Settings.sharedInstance.convertKmToMil(distanceValue[0], toMil: false)
                }
            }
            if(timeStr.isEmpty == true) {
                timeStr = ""
                if(Double(distanceValue[0]) == 0.0) {
                    cell.setParameters.text = ""
                }else {
                    cell.setParameters.text = "\(distance) \(Settings.sharedInstance.currentDistanceUnit)"
                }
            }else {
                if(Double(distanceValue[0]) == 0.0) {
                    cell.setParameters.text = "\(timeStr)"
                }else {
                    cell.setParameters.text = "\(distance) \(Settings.sharedInstance.currentDistanceUnit), \(timeStr)"
                }
            }
            return cell
        }else {
            if(self.sortedSets[key]![indexPath.row]!.sets == nil) {
                return cell
            }
            let weightValue = self.sortedSets[key]![indexPath.row]!.sets![0].rightValue!.characters.split{$0 == ":"}.map(String.init)
            let rightValue:String!
            if(weightValue[1] == str_kg) {
                if(weightValue[1] == Settings.sharedInstance.currentWightUnit) {
                    rightValue = weightValue[0]
                }else {
                    rightValue = Settings.sharedInstance.convertKgToPd(weightValue[0], toPd: true)
                }
            }else {
                if(weightValue[1] == Settings.sharedInstance.currentWightUnit) {
                    rightValue = weightValue[0]
                }else {
                    rightValue = Settings.sharedInstance.convertKgToPd(weightValue[0], toPd: false)
                }
            }
            cell.setParameters.text = "\(self.sortedSets[key]![indexPath.row]!.sets![0].leftValue) x \(rightValue) " + type
            return cell
        }
        
    }
}
