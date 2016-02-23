//
//  ExercisesInWorkoutVC.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/7/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import MBProgressHUD
import Parse

protocol ExercisesInWorkoutVCProtocol {
    func isAddExercises(array: Array<ExerciseTemplate>)
}

class WorkoutRelation {
    var id:String!
    var priority:Int!
    
    init(id:String,pri:Int) {
        self.id = id
        self.priority = pri
    }
}

class ExercisesInWorkoutVC: UIViewController {
    var exercises:Array<ExerciseTemplate>!
    var workoutExercises:Array<WorkoutRelation>!
    var isNew:Bool!
    var isEdit:Bool!
    var swipeBack:UISwipeGestureRecognizer!
    var selectedExercise:ExerciseTemplate!
    var block:Bool!
    var isChanged:Bool!
    var progressHUD:MBProgressHUD!
    var isEmpty:Bool!
    var cont:Int!
    var bestResults:[String:String]!
    @IBOutlet var tableView: UITableView!

    var workoutName:String!
    var workoutId:String!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        bestResults = [String:String]()

        isChanged = false
        isEdit = false
        self.workoutId = "class" + self.workoutId
        
        self.exercises = Array<ExerciseTemplate>()
        tableView.allowsSelectionDuringEditing = true
        if(isNew == true) {
            true
            let addExerciseVC = self.storyboard?.instantiateViewControllerWithIdentifier("AddExerciseVC") as! AddExerciseVC
            addExerciseVC.workoutName = workoutId
            addExerciseVC.delegate = self
            let navigationController = UINavigationController(rootViewController: addExerciseVC)
            
            self.presentViewController(navigationController, animated: true, completion: nil)
        }else {
            self.exercises = Array<ExerciseTemplate>()
            self.tableView.dataSource = self;
            self.tableView.delegate = self;
            self.progressHUD = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow, animated: true)
            self.progressHUD.labelText = str_Loading
            self.loadFromiCloud()

            
            
        }
        let editButton = UIBarButtonItem(title: str_Edit, style: UIBarButtonItemStyle.Done, target: self, action: "editButtonClick")
        //let font = UIFont(descriptor: UIFontDescriptor(name: "SanFranciscoDisplay", size: 16), size: 16)
        editButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFontOfSize(16) ], forState: UIControlState.Normal)
        self.navigationItem.rightBarButtonItem = editButton

        self.navigationController?.navigationBar.tintColor = UIColor(rgba: "#ff3e50ff")
        var str = workoutName
        if(workoutName.characters.count > 15) {
            let i =  15
            while(i != str.characters.count) {
                str.removeAtIndex(str.endIndex.predecessor())
            }
            str = str + "..."

        }
        self.navigationItem.title = str
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
//
//        

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if(Settings.sharedInstance.isResetState == true) {
            self.navigationController?.popToRootViewControllerAnimated(false)
        }
        self.bestResults.removeAll()
        self.tableView.reloadData()
        self.block = false
    }
    
    func getExerciseFromHistory(exercise:ExerciseTemplate,bestValueLabel:UILabel) {
        var bestValue = "0"
        var bestDistance:Double = 0
        var bestHour = 25
        var bestMin  = 60
        var bestSec = 60
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            UserExercisesManager.sharedInstance.getExerciseHistory(exercise.id,     onSuccess: { (result) -> Void in
                if(result.count == 0 ) {
                    return
                }
                for item in result {
                    self.isBest((item.sets?[0].rightValue)!,leftValue: (item.sets?[0].leftValue)! , date: NSDate.toString(item.date!),exercise:exercise,bestValue:&bestValue,bestDistance:&bestDistance,bestHour:&bestHour,bestMin:&bestMin,bestSec:&bestSec)
                    
                    //self.isBest((item.sets?[0].rightValue)!, leftValue: (item.sets?[0].leftValue)!, date: NSDate.toString(item.date!))
                }
                let type = exercise.type == "Weight" ?Settings.sharedInstance.currentWightUnit: Settings.sharedInstance.currentDistanceUnit
                dispatch_async(dispatch_get_main_queue()) {
                    if(exercise.type == "Weight") {
                        self.bestResults[exercise.id] = bestValue + " " + type
                        bestValueLabel.text = bestValue + " " + type
                    }else {
                        let hour = bestHour < 10 ? "0\(bestHour)" : "\(bestHour)"
                        let min = bestMin < 10 ? "0\(bestMin)" : "\(bestMin)"
                        let sec = bestSec < 10 ? "0\(bestSec)" : "\(bestSec)"
                        
                        self.bestResults[exercise.id] = "\(bestDistance) \(Settings.sharedInstance.currentDistanceUnit), \(hour ):\(min):\(sec)"
                        bestValueLabel.text =  "\(bestDistance) \(Settings.sharedInstance.currentDistanceUnit), \(hour ):\(min):\(sec)"
                        
                    }
                }
            })
            
        }
        
    }
    func isBest(rightValue:String,leftValue:String,date: String,exercise:ExerciseTemplate,inout bestValue:String,inout bestDistance:Double,inout bestHour:Int,inout bestMin:Int,inout bestSec:Int) {
        if(exercise.type == "Weight") {
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
            if(Double(weightStr) > Double(bestValue)! ) {
                
                bestValue = weightStr
                
                
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
            if(bestDistance <= Double(distanceStr)) {
                let time =  rightValue.characters.split{$0 == ":"}.map(String.init)
                if(Int(time[0]) <= bestHour ) {
                    if(Int(time[1]) <= bestMin ) {
                        if(Int(time[2]) <= bestSec ) {
                            bestDistance = Double(distanceStr)!
                            bestHour = Int(time[0])!
                            bestMin = Int(time[1])!
                            bestSec = Int(time[2])!
                        }
                    }
                    
                }
            }
        }
        
    }

    func loadFromiCloud() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            while(ExerciseManager.sharedInstance.count != -1) {
                
            }
            let getQuery = PFQuery(className: self.workoutId)
            getQuery.fromLocalDatastore()
            getQuery.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
                var exIdArray = [String]()
                var dictPriority = [String:Int]()
                for item in objects! {
                        exIdArray.append(item["exerciseId"] as! String)
                        dictPriority[item["exerciseId"] as! String] = item["exercisePriority"] as? Int
                }
                let exercisesArray = ExerciseManager.sharedInstance.getExercisesById(exIdArray)
                for item in exercisesArray {
                    self.exercises.append(ExerciseTemplate(id: item.objectId, name: item.exerciseName, checked: false, custom: true, used: item.usedCount, type: item.type,priority: dictPriority[item.objectId]))
                }
                self.exercises = self.exercises.sort() { $0.priority < $1.priority }
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    self.progressHUD.hide(true)
                }


            }
        }
    }


    func backButtonClick(){
        if(tableView.editing != true) {
            self.navigationController?.popViewControllerAnimated(true)

        }
    }
    
    func editButtonClick(){
        if(self.tableView.editing == true) {
            self.navigationItem.setHidesBackButton(false, animated: false)
            self.tableView.editing = false
            self.tableView.reloadData()
            self.navigationItem.rightBarButtonItem?.title = str_Edit
            for var i = 0;i < self.exercises.count;i++ {
                if(self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i , inSection: 0)) != nil ) {
                    let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i , inSection: 0)) as! ExerciseDetailCell
                    cell.setParameters.hidden = false
                }

            }
            if(isChanged == true) {
            
                
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.saveData()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    })
                })

                
            }
            
            isEdit = false
            
            return
        }
        
        self.navigationItem.setHidesBackButton(true, animated: false)
        isChanged = false
        self.navigationItem.rightBarButtonItem?.title = str_Done
        self.tableView.editing = true
        isEdit = true
        self.tableView.reloadData()
        for var i = 1;i < self.exercises.count + 1;i++ {
            if(self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i , inSection: 0)) != nil ) {
                let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i , inSection: 0)) as! ExerciseDetailCell
                cell.setParameters.hidden = true
            }
        }
    }
    
    func saveData() {
        let query = PFQuery(className: workoutId)
        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock { (results, error ) -> Void in
            for object in results! {
                object["exercisePriority"] =  self.exercises.indexOf() { $0.id == object["exerciseId"] as! String! }
                object.pinInBackground()
                
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "addExercise") {
            let addExerciseNC = segue.destinationViewController as! UINavigationController
            let addExerciseVC = addExerciseNC.viewControllers.first as! AddExerciseVC
            addExerciseVC.workoutName = workoutId
            addExerciseVC.delegate = self
            
            
        }else if(segue.identifier == "exerciseDetail") {
            let exerciseDetailVC = segue.destinationViewController as! ExerciseDetailViewController
            
            exerciseDetailVC.transportIndex = self.exercises.indexOf() { $0.id == self.selectedExercise.id}
            exerciseDetailVC.transportExercises = self.exercises
            exerciseDetailVC.workoutId = workoutId
            exerciseDetailVC.hidesBottomBarWhenPushed = true
            exerciseDetailVC.isEmpty = false
            
        }
    }
    
    func getUpPriority(array: Array<ExerciseTemplate>) {
            let priorityQuery = PFQuery(className: workoutId)
            priorityQuery.fromLocalDatastore()
            priorityQuery.findObjectsInBackgroundWithBlock({ (objects, error ) -> Void in
                self.exercises = array
                var pri = 0
                for item in objects! {
                    if((item.valueForKey("exercisePriority") as! Int) < 0) {
                        pri++
                    }
                }
                for item in objects! {
                    if((item.valueForKey("exercisePriority") as! Int) > -1) {
                       let index =  self.exercises.indexOf() { $0.id == item["exerciseId"] as! String }
                        self.exercises[index!].priority = pri + (item.valueForKey("exercisePriority") as! Int)
                        item.setValue(pri + (item.valueForKey("exercisePriority") as! Int), forKey: "exercisePriority")
                    }
                }
                var newPriority = 0
                var currentPri = -1
                while(pri != 0) {
                    var tempItem = objects![0]
                    for item in objects! {
                        let itemValue = (item.valueForKey("exercisePriority") as! Int)
                        if(itemValue < 0) {
                            if(itemValue == currentPri) {
                                tempItem = item
                                break
                            }
                        }
                    }
                    tempItem.setValue(newPriority, forKey: "exercisePriority")
                    let index =  self.exercises.indexOf() { $0.id == tempItem["exerciseId"] as! String }
                    self.exercises[index!].priority = newPriority
                    tempItem.pinInBackground()
                    pri = pri - 1
                    currentPri = currentPri - 1
                    newPriority = newPriority + 1
                }
                self.exercises = self.exercises.sort() { $0.priority < $1.priority }
                self.tableView.reloadData()
                self.editButtonClick()
            })
    }
}

extension ExercisesInWorkoutVC: ExercisesInWorkoutVCProtocol {
    func isAddExercises(array: Array<ExerciseTemplate>) {
            self.exercises.removeAll()
            self.tableView.reloadData()
            getUpPriority(array)
    
        
    }
}

extension ExercisesInWorkoutVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {
            switch editingStyle {
            case .Delete:
                if(self.navigationItem.rightBarButtonItem?.title == str_Done) {
                    removeFromLocal(self.exercises[indexPath.row-1])
                    self.exercises.removeAtIndex(indexPath.row-1)
                    saveData()
                }else {
                    removeFromLocal(self.exercises[indexPath.row])
                    self.exercises.removeAtIndex(indexPath.row)
                    saveData()
                }
            default:
                return
           }
    }
    
    func removeFromLocal(item:ExerciseTemplate){
        let copuItem = item.copy() as! ExerciseTemplate
        let query = PFQuery(className: workoutId)
        query.fromLocalDatastore()
        query.whereKey("exerciseId", equalTo: copuItem.id)
        query.findObjectsInBackgroundWithBlock { (result, errr) -> Void in
            let res = result?[0]
            res!.unpinInBackground()
            ExerciseManager.sharedInstance.decreaseExerciseCount(copuItem.id)
            self.tableView.reloadData()
        }
       
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if(destinationIndexPath.row == 0) {
            tableView.reloadData()
            return
        }
        isChanged = true
        if(sourceIndexPath.row > destinationIndexPath.row) {
            let temp = self.exercises[sourceIndexPath.row - 1]
            for index in (destinationIndexPath.row - 1...sourceIndexPath.row - 1).reverse() {
                if((index - 1) >= destinationIndexPath.row - 1) {
                    self.exercises[index] = self.exercises[index - 1]
                }
            }
            self.exercises[destinationIndexPath.row - 1] = temp
        }else {
            let temp = self.exercises[sourceIndexPath.row - 1]
            for index in sourceIndexPath.row - 1...destinationIndexPath.row - 1 {
                if((index + 1) <= destinationIndexPath.row - 1) {
                    self.exercises[index] = self.exercises[index + 1]
                }
            }
            self.exercises[destinationIndexPath.row - 1] = temp
        }
        
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if(indexPath.row == 0 && tableView.editing == true){
            return false
        }
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ExerciseDetailCell") as! ExerciseDetailCell
        if((tableView.editing == true) && (indexPath.row == 0)) {
            let cell = (tableView.dequeueReusableCellWithIdentifier("createCell") as? AddExerciseCell)!
            cell.separatorInset = UIEdgeInsets(top: (cell.separatorInset.top), left: (cell.frame.width)*2, bottom: 0, right: 0)
            return cell
        }
        
        
        //cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        cell.selectionStyle = UITableViewCellSelectionStyle.Default
        var index = indexPath.row
        if(tableView.editing == true) {
            index -= 1
        }
        //cell.textLabel!.text = exercises[index].name
        cell.setName.text = exercises[index].name
        cell.setParameters.text = ""
        if let _ = bestResults[exercises[index].id] {
            cell.setParameters.text = bestResults[exercises[index].id]
        }else {
            self.getExerciseFromHistory(exercises[index], bestValueLabel: cell.setParameters)
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (tableView.editing == true) {
            return exercises.count + 1
        }else {
            return exercises.count
        }

        
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55;
    }
    
    
}
extension ExercisesInWorkoutVC: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if(block == true) {
            return
        }
        
        if(self.tableView == tableView) {
            block = true
            if((indexPath.row == 0)&&(tableView.editing == true)){
                self.performSegueWithIdentifier("addExercise", sender: self)
            }else if(tableView.editing == false){
                selectedExercise = exercises[indexPath.row]
                self.performSegueWithIdentifier("exerciseDetail", sender: self)
                self.isEmpty = false
                
            }
        }
        
        
        
    }
}
