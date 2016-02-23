//
//  AddExerciseVC.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/5/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD
protocol AddExerciseVCProtocol {
    func addNewCustomExercise(newItem:Exercise) -> Bool
}

let EXERCISE_STORE = "ExerciseStore"
class AddExerciseVC: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    var workoutName:String!
    var searchTableView :UITableView!
    var isSearch:Bool!
    var currentIndex:Int!
    var progressHUD:MBProgressHUD!
    var currentItems:Array<ExerciseTemplate>!
    var exercises:Array<Exercise>!
    var delegate:ExercisesInWorkoutVCProtocol?
    var currentPriority:Int!
    var isFirstEntry:Bool!
    var unSelected: [String : Bool]!
    
//    var currentItems:Array<String> = ["Exercise1","Exercise2","Exercise3","Exercise4","Exercise5","Exercise6",
//                                       "Exercise7","Exercise8","Exercise9","Exercise10","Exercise11",]
    var resultSearchItems:Array<ExerciseTemplate> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isFirstEntry = true
        currentPriority = -1
        currentItems = Array<ExerciseTemplate>()
        resultSearchItems = Array<ExerciseTemplate>()
        isSearch = false
        exercises = Array<Exercise>()
        unSelected = [String : Bool]()

        self.loadExercises()
        self.navigationItem.setHidesBackButton(false, animated: false)
        let doneButton = UIBarButtonItem(title: str_Done, style: UIBarButtonItemStyle.Done, target: self, action: "doneButtonClick")
        self.navigationItem.rightBarButtonItem = doneButton
        self.navigationController?.navigationBar.tintColor = UIColor(rgba: "#ff3e50ff")
        self.navigationItem.title = str_AddExercise
        self.navigationController!.view.backgroundColor = UIColor.whiteColor()

        
    }

    @IBAction func doneAction(sender: UIBarButtonItem) {
        progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        progressHUD.labelText = str_Loading
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            
            // ...Run some task in the background here...
            self.saveItemInLocalDataStore(self.currentItems)
            dispatch_async(dispatch_get_main_queue()) {
                
                
                
                // ...Run something once we're done with the background task...
            }
        }

    }
    func loadExercises() {
        loadDefaultExerciseIntoArray()
    }
    func loadWorkoutExerciseInformation() {
        let infoQuery = PFQuery(className: workoutName)
        infoQuery.fromLocalDatastore()
        infoQuery.findObjectsInBackgroundWithBlock { (informations, error ) -> Void in
            for exerc in self.exercises {
                self.currentItems.append(ExerciseTemplate(id: exerc.objectId, name: exerc.exerciseName, checked: false, custom: exerc.isCustom, used: exerc.usedCount, type:exerc.type, priority: -1))
            }
            for info in informations! {
                let exerciseId = info["exerciseId"] as! String
                let exercisePriority = info["exercisePriority"] as! Int

                let index = self.currentItems.indexOf() {$0.id == exerciseId}
                if(index != -1) {
                    self.currentItems[index!].checked = true
                    self.unSelected[self.currentItems[index!].name] = true
                    self.isFirstEntry = false
                    self.currentItems[index!].priority = exercisePriority
                }

            }
            if(informations!.count == 0) {

            }
            self.currentItems = self.sortArray(self.currentItems)
            self.tableView.reloadData()
            
        }
    }
    func sortArray(var array:Array<ExerciseTemplate>) -> Array<ExerciseTemplate> {
        var defaultArray = array.filter() { ($0.used == 0 && $0.custom == false)  }
        var usercustomArrayUsed = array.filter() { (($0.used != 0) && $0.custom == false)  }
        var usercustomArrayNotUsed = array.filter() { ($0.custom == true)  }
        
        array.removeAll()
        if(usercustomArrayNotUsed.count != 0) {
            usercustomArrayNotUsed.sortInPlace { $0.name.compare($1.name) == .OrderedAscending}
            array += usercustomArrayNotUsed
        }
        if(usercustomArrayUsed.count != 0) {
            usercustomArrayUsed.sortInPlace { $0.name.compare($1.name) == .OrderedAscending}
            array += usercustomArrayUsed
        }
        if(defaultArray.count != 0) {
            defaultArray.sortInPlace { $0.name.compare($1.name) == .OrderedAscending}
            array += defaultArray
        }
        return array
    }
    func loadDefaultExerciseIntoArray() {

        self.exercises = ExerciseManager.sharedInstance.getExercises()
        self.loadWorkoutExerciseInformation()
    }
    func doneButtonClick() {
        progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        progressHUD.labelText = str_Loading
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            
            // ...Run some task in the background here...
            
            dispatch_async(dispatch_get_main_queue()) {
                self.saveItemInLocalDataStore(self.currentItems)
                
                
                // ...Run something once we're done with the background task...
            }
        }
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func searchThroughtData() -> Void {
        
        resultSearchItems = currentItems.filter() {
            
            if($0.name.lowercaseString.containsString((searchBar.text?.lowercaseString)!)) {
                return true
            }else {
                return false
            }
            
//            let words = $0.name.lowercaseString.characters.split{$0 == " "}.map(String.init)
//            for word in words {
//                var wordSucces = true
//                var externalIndex = 0
//                for charWord in word.lowercaseString.characters {
//                    var internalIndex = 0
//                    for char in (searchBar.text?.lowercaseString.characters)! {
//                        if(externalIndex == internalIndex) {
//                            if(charWord == char) {
//                                break
//                            }else {
//                                wordSucces = false
//                                break
//                            }
//                        }else {
//                            internalIndex++
//                        }
//                    }
//                    if(wordSucces == false) {
//                        break
//                    }
//                    externalIndex++
//                }
//                if(wordSucces == true) {
//                    return true
//                }
//            }
            return false
        }
    }
    
    func saveItemInLocalDataStore(items:Array<ExerciseTemplate>) {
        for item in self.currentItems {
            if(self.unSelected.keys.contains(){ $0 == item.name}) {
                if(self.unSelected[item.name] == false) {
                    let deleteQuery = PFQuery(className: workoutName)
                    deleteQuery.fromLocalDatastore()
                    deleteQuery.whereKey("exerciseId", containsString: item.id)
                    deleteQuery.getFirstObjectInBackgroundWithBlock({ (deleteObject, err ) -> Void in
                        deleteObject!.unpinInBackground()
                    })
                    ExerciseManager.sharedInstance.decreaseExerciseCount(item.id)
                    
                }
            }
            if(item.checked == true) {
                let saveQuery = PFQuery(className: workoutName)
                saveQuery.fromLocalDatastore()
                saveQuery.whereKey("exerciseId", containsString: item.id)
                var saveObject:PFObject!
                do {
                   saveObject  = try saveQuery.getFirstObject()
                }catch {
                    
                }
                if(saveObject == nil) {
                    let newExerciseInWorkout = PFObject(className: self.workoutName)
                    newExerciseInWorkout["exerciseId"] = item.id
                    newExerciseInWorkout["exercisePriority"] = item.priority
                   
                    newExerciseInWorkout.ownSaveEventually({ (success, error ) -> Void in
                        if(success) {
                            newExerciseInWorkout.pinInBackground()
                            ExerciseManager.sharedInstance.increaseExerciseCount(item.id)
                        }
                    })
                }
                
            }
        }
        self.progressHUD.hide(true)
        self.delegate?.isAddExercises(self.currentItems.filter(){$0.checked == true})
        self.dismissViewControllerAnimated(true, completion: nil)

}
    }
extension AddExerciseVC :AddExerciseVCProtocol {
    func addNewCustomExercise(newItem: Exercise) -> Bool{
        self.currentItems.insert(ExerciseTemplate(id: newItem.objectId, name: newItem.exerciseName, checked: true, custom: true, used: newItem.usedCount,type: newItem.type, priority: -1), atIndex: 0)
        //self.currentItems = sortArray(self.currentItems)
        self.tableView.reloadData()
        return false
        
    }
}
extension AddExerciseVC: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        var cell = tableView.dequeueReusableCellWithIdentifier("cell") as? AddExerciseCell
        if(cell == nil) {
            cell = self.tableView.dequeueReusableCellWithIdentifier("cell") as? AddExerciseCell
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        }
        if((indexPath.row == 0) && (tableView == self.tableView) ) {
            cell = tableView.dequeueReusableCellWithIdentifier("createCell") as? AddExerciseCell
            cell?.separatorInset = UIEdgeInsets(top: (cell?.separatorInset.top)!, left: (cell?.frame.width)!, bottom: 0, right: 0)
            return cell!
        }
        cell!.selectionStyle = UITableViewCellSelectionStyle.None
        if(tableView == self.tableView) {
            isSearch = false
            resultSearchItems.removeAll()
            cell!.mainLabel!.text = currentItems[indexPath.row - 1].name
            if(currentItems[indexPath.row - 1].checked == true) {
                cell!.addImage.image = UIImage(named: "added_icon")
                cell!.addedLabel.text = str_Added
            }else {
                //let addGestureRecognizer = UITapGestureRecognizer(target: self, action: "addToWorkoutTap:")
                //cell!.tapView.addGestureRecognizer(addGestureRecognizer)
                cell!.addImage.image = UIImage(named: "add_icon")
                cell!.addedLabel.text = ""
            }
        }else {
            isSearch = true
            cell!.mainLabel!.text = resultSearchItems[indexPath.row].name
            if(resultSearchItems[indexPath.row].checked == true) {
                cell!.addImage.image = UIImage(named: "added_icon")
                cell!.addedLabel.text = str_Added

            }else {
               // let addGestureRecognizer = UITapGestureRecognizer(target: self, action: "addToWorkoutTap:")
                //cell!.tapView.addGestureRecognizer(addGestureRecognizer)
                cell!.addImage.image = UIImage(named: "add_icon")
                cell!.addedLabel.text = ""
            }
        }
        
        
        return cell!
    }
   

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == self.tableView) {
            tableView.rowHeight = 55
           //currentItems =  sortArray(currentItems)
           return self.currentItems.count + 1;
            
        }else {
            searchTableView = tableView
            searchTableView.rowHeight = 55
            //resultSearchItems =  sortArray(resultSearchItems)
            return self.resultSearchItems.count
        }
        
    }
    
    
}
extension AddExerciseVC: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(self.tableView == tableView) {
            if(indexPath.row == 0){
                let createExercise = self.storyboard?.instantiateViewControllerWithIdentifier("CreateCustomExercise") as! CreateCustomExercise
                createExercise.delegate = self
                let navigationController = UINavigationController(rootViewController: createExercise)
                
                self.presentViewController(navigationController, animated: true, completion: nil)
                return
            }
            
        }
        if(isSearch == true){
            
            let tempObject = resultSearchItems[indexPath.row]
            let index = currentItems.indexOf{ (($0.name == tempObject.name) && ($0.checked == tempObject.checked))  }
            currentItems[index!].checked == true ? (currentItems[index!].checked = false) : (currentItems[index!].checked = true)
            resultSearchItems[indexPath.row].checked == true ?  (resultSearchItems[indexPath.row].checked = true) : (resultSearchItems[indexPath.row].checked = false)
            resultSearchItems[indexPath.row].priority = currentPriority
            resultSearchItems[indexPath.row].checked == true ? (resultSearchItems[indexPath.row].used = resultSearchItems[indexPath.row].used - 1) : (resultSearchItems[indexPath.row].used = resultSearchItems[indexPath.row].used + 1)
            searchTableView.reloadData()
            resultSearchItems[indexPath.row].checked == true ? (currentPriority = currentPriority - 1) : (currentPriority = currentPriority + 1)
            if(self.unSelected.keys.contains() { $0 == currentItems[index!].name}) {
                if(self.unSelected[currentItems[index!].name] == true) {
                    self.unSelected[currentItems[index!].name] = false
                }else {
                    self.unSelected[currentItems[index!].name] = true
                }
                
            }
            
           
        }else {
            currentItems[indexPath.row - 1].checked == true ? (currentItems[indexPath.row - 1].checked = false) : (currentItems[indexPath.row - 1].checked = true)
            currentItems[indexPath.row - 1].priority = currentPriority
            currentItems[indexPath.row - 1].checked == true ? (currentItems[indexPath.row - 1].used = currentItems[indexPath.row - 1].used - 1) : (currentItems[indexPath.row - 1].used = currentItems[indexPath.row - 1].used + 1)
            tableView.reloadData()
            currentItems[indexPath.row - 1].checked == true ? (currentPriority = currentPriority - 1) : (currentPriority = currentPriority + 1)
            if(self.unSelected.keys.contains() { $0 == currentItems[indexPath.row - 1].name}) {
                if(self.unSelected[currentItems[indexPath.row - 1].name] == true) {
                     self.unSelected[currentItems[indexPath.row - 1].name] = false
                }else {
                    self.unSelected[currentItems[indexPath.row - 1].name] = true
                }
               
            }
        }
        
        
        
    }
}
extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}
extension AddExerciseVC: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchThroughtData()
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        tableView.reloadData()
    }
}
