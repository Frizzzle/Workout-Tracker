//
//  HistoryViewController.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/27/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
 
import MBProgressHUD
import Parse

class HistoryRecordHandler:ExerciseHistoryTemplate {
    var workoutId:String!
}

class CellStates {
    var section:Int!
    var row:Int!
    var expanded:Bool!
    var inner:Bool!
    
    init(section:Int,row:Int,expanded:Bool,inner:Bool) {
        self.section = section
        self.row = row
        self.expanded = expanded
        self.inner = inner
    }
}

class HistoryViewController: UIViewController {
    var cellStates:[CellStates]!
    var progressHUD:MBProgressHUD!
    var records:[ExerciseHistoryTemplate]!
    var sortedSets:[String : [ExerciseHistoryTemplate!]]!
    var sortedHistory:[String : [String : [ExerciseHistoryTemplate!]]]!
    var selectedDate:String!
    var selectedName:String!
    var selectedSetName:String!
    var countExercise:Int!
    var countExpanded:Int!
    var selectedSet:ExerciseHistoryTemplate!
    var deletedItem:ExerciseHistoryTemplate!
    var countQuery:Int!
    var globalRemoveCount:Int!
    var summHour:Int!
    var summMin:Int!
    var summSec:Int!
    var sortedDate:[String]!
    var sortedExercise:[String : [String]]!
    var summDistance:Double!
    var exerciseNameDict:[String : String]!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.exerciseNameDict = [String : String]()
        self.navigationItem.title = str_History
    }
    
    @IBOutlet var emptyHistoryScreen: UIView!
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //self.emptyHistoryScreen.hidden = false
        loadHistory()
        
    }
    
    @IBOutlet var tableView: UITableView!
    
    func loadHistory() {
        self.sortedHistory = [String : [String : [ExerciseHistoryTemplate!]]]()
        self.countExercise = 0
        countExpanded = 0
        self.cellStates = [CellStates]()
        self.records = [HistoryRecordHandler]()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            UserExercisesManager.sharedInstance.getHistory({ (result) -> Void in
                if(result.count == 0) {
                    self.emptyHistoryScreen.hidden = false
                    return
                }
                self.records = result
                self.sortSetsForData()
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    self.emptyHistoryScreen.hidden = true
                }
            })
            
        }
        
    }
    
    
    func getExerciseName(idExercise:String?,label:UILabel) -> String {
        if(idExercise == nil) {
            return ""
        }
        
        if let _  = exerciseNameDict[idExercise!] {
            label.text =  exerciseNameDict![idExercise!]
        }else {
            self.exerciseNameDict[idExercise!] = ExerciseManager.sharedInstance.getExercisesById([idExercise!])[0].exerciseName
            label.text = self.exerciseNameDict[idExercise!]
        }
        
        
        return ""
    }
    
    func sortSetsForData() {
        if(self.sortedHistory == nil) {
            return
        }
        
        self.sortedDate = [String]()
        for record in self.records{
            let key = NSDate.toString(record.date!)
            if let _ = sortedHistory[key] {
                if let _ =  sortedHistory[key]?[record.idExercise!] {
                    sortedHistory[key]?[record.idExercise!]?.append(record)
                }else {
                    sortedHistory[key]?[record.idExercise!] = [ExerciseHistoryTemplate]()
                    sortedHistory[key]?[record.idExercise!]?.append(record)
                }
            }else {
                //sortedHistory[key!] = [String : [ExerciseHistoryTemplate!]]()
                
                sortedHistory.updateValue([String : [ExerciseHistoryTemplate!]](), forKey: key)
                self.sortedDate.append(key)
                sortedHistory[key]?[record.idExercise!] = [ExerciseHistoryTemplate]()
                
                sortedHistory[key]?[record.idExercise!]?.append(record)
            }
        }
        self.sortDate()
    }
    func sortDate() {
        self.sortedDate.sortInPlace { (left, right) -> Bool in
            if(NSDate.date(left).isLessThanDate(NSDate.date(right)) == true) {
                return false
            }
            return true
        }
        var section = 0
        for date in self.sortedDate {
            for array in 0...self.sortedHistory[date]!.count - 1 {
                cellStates.append(CellStates(section: section, row: array, expanded: false, inner: false))
            }
            section = section + 1
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "setDetailWeightHistory") {
            let setupSetVC = segue.destinationViewController as! SetWeightVC
            setupSetVC.data = selectedSet.date
            setupSetVC.isNewSet = false
            setupSetVC.setName = selectedSetName
            setupSetVC.selectedSet = selectedSet
            setupSetVC.isHistory = true
            
            setupSetVC.hidesBottomBarWhenPushed = true
            let backItem = UIBarButtonItem()
            backItem.title = " "
            navigationItem.backBarButtonItem = backItem
            setupSetVC.currentExercise = ExerciseTemplate(id: selectedSet.idExercise!, name: "", checked: false, custom: false, used: 0, type: selectedSet.type, priority: -1)
            self.progressHUD.hide(true)
        }else {
            let setupSetVC = segue.destinationViewController as! SetDistanceVC
            let type = selectedSet!.type
            let id = selectedSet!.idExercise!
            setupSetVC.currentExercise = ExerciseTemplate(id: id, name: "", checked: false, custom: false, used: 0, type: type, priority: -1)
            
            setupSetVC.data = selectedSet.date
            setupSetVC.isNewSet = false
            setupSetVC.isHistory = true
            setupSetVC.setName = selectedSetName
            setupSetVC.selectedSet = selectedSet
            
            
            setupSetVC.hidesBottomBarWhenPushed = true
            let backItem = UIBarButtonItem()
            backItem.title = " "
            navigationItem.backBarButtonItem = backItem
            
            
            self.progressHUD.hide(true)
            
        }
    }
    
    func isInner(indexPath:NSIndexPath) -> Bool {
        
        for state in cellStates {
            if((state.section == indexPath.section)&&(state.row == indexPath.row)&&(state.inner == true)) {
                return true
            }
        }
        return false
    }
    
    func offsetStates(startSection:Int,startRow:Int,countOffset:Int,reverse:Bool) {
        var index = 0
        if(reverse == false) {
            while (true) {
                if((cellStates[index].section == startSection)&&((cellStates[index].row == startRow))) {
                    cellStates[index].expanded = true
                    
                    for i in 1...countOffset {
                        
                        cellStates.insert(CellStates(section: startSection, row: cellStates[index].row + i, expanded: false, inner: true), atIndex: index + i)
                    }
                    if((index + (countOffset + 1)) > (cellStates.count - 1)) {
                        break
                    }
                    for ind in (index + (countOffset + 1))...(cellStates.count - 1) {
                        if(cellStates[ind].section == cellStates[index].section) {
                            cellStates[ind].row = cellStates[ind - 1].row + 1
                        }else {
                            break;
                        }
                    }
                    break
                }
                index = index + 1
            }
            
        }else {
            while (true) {
                if((cellStates[index].section == startSection)&&((cellStates[index].row == startRow))) {
                    cellStates[index].expanded = false
                    for _ in 1...countOffset {
                        cellStates.removeAtIndex(index + 1)
                    }
                    if((index + 1) > (cellStates.count - 1)) {
                        break
                    }
                    for ind in (index + 1)...(cellStates.count - 1) {
                        if(cellStates[ind].section == cellStates[index].section) {
                            cellStates[ind].row = cellStates[ind - 1].row + 1
                        }else {
                            break;
                        }
                    }
                    break
                }
                index = index + 1
            }
            
        }
        
    }
    
    func getCountRowInSection(section:Int) -> Int {
        var countRow = 0
        for state in cellStates {
            if(state.section == section) {
                countRow = countRow + 1
            }
        }
        return countRow
    }
    
    func getDateKey(indexPath:Int) -> String {
        
        //let intIndex =  // where intIndex < myDictionary.count
        //let index = self.sortedHistory.startIndex.advancedBy(intIndex)
        
        if(self.sortedDate.count == 0) {
            return "";
        }
        
        return self.sortedDate[indexPath]
    }
    
    func getUnSortedIndex(index:Int) -> Int {
        return 0
    }
    
    
    func getNameKey(indexPath:NSIndexPath,dateKey:String!) -> String {
        
        let trueIndex = getTrueIndex(indexPath)
        
        let intIndex = trueIndex // where intIndex < myDictionary.count
        let index = self.sortedHistory[dateKey]!.startIndex.advancedBy(intIndex)
        
        
        
        return self.sortedHistory[dateKey]!.keys[index]
    }
    
    func getTrueIndex(indexPath:NSIndexPath) -> Int {
        
        var trueIndex = 0
        for state in cellStates {
            if((state.row == indexPath.row)&&(state.section == indexPath.section)/*&&(state.inner == false)*/) {
                return trueIndex
            }
            if((state.inner == false)&&(state.section == indexPath.section)) {
                trueIndex = trueIndex + 1
            }
        }
        
        return trueIndex
    }
    
    
    func getExternalIndex(indexPath:NSIndexPath) -> Int{
        var externalIndex = -1
        for state in cellStates {
            if((state.inner == false)&&(state.section == indexPath.section)&&(state.row >= indexPath.row)) {
                return externalIndex
            }else if((state.inner == false)&&(state.section == indexPath.section)){
                externalIndex = externalIndex + 1
            }
        }
        
        return externalIndex
    }
    
    func getInnerIndex(externalIndex:Int,indexPath:NSIndexPath) -> Int {
        var tempEx = 0
        var tempIn = 0
        var innerIndex = 0
        var lock = false
        for index in 0...cellStates.count {
            if(cellStates[index].section == indexPath.section) {
                if(cellStates[index].inner == false && externalIndex != tempEx) {
                    tempEx = tempEx + 1
                }else if(cellStates[index].inner == false && externalIndex == tempEx) {
                    lock = true
                    tempIn = tempIn + 1
                    continue
                }
                if(lock == true) {
                    if (tempIn == indexPath.row) {
                        return innerIndex
                    }else {
                        innerIndex = innerIndex + 1
                    }
                }
                tempIn = tempIn + 1
            }
            
        }
        
        return 0
    }
    
    func removeDateFromTables(deleteArray: [ExerciseHistoryTemplate!]) {
        var index = deleteArray.count
        self.globalRemoveCount = index
        while (index != 0) {
            removeObjectFromTables(deleteArray[index - 1],isMassivRemoving: true)
            index = index - 1
        }
    }
    func decreaseCountRemoving(){
        
        self.globalRemoveCount = self.globalRemoveCount - 1
        self.countQuery = 2
        if(self.globalRemoveCount < 1) {
            self.progressHUD.hide(true)
            //self.loadHistory()
            if(self.cellStates.count != 0) {
               self.tableView.reloadData()
            }else {
                self.emptyHistoryScreen.hidden = false;
                self.tableView.reloadData()
            }
            
        }
    }
    
    func removeObjectFromTables(deleteItem:ExerciseHistoryTemplate,isMassivRemoving:Bool) {
        
            UserExercisesManager.sharedInstance.deleteExercise((deleteItem.sets?[0].idSet!)!) { () -> Void in
                let date = NSDate.toString(deleteItem.date!)
                let idExercise = deleteItem.idExercise!
                if(isMassivRemoving == true) {
                    if(self.sortedHistory[date] != nil) {
                        if(self.sortedHistory[date]?.count < 1) {
                            self.sortedHistory.removeValueForKey(date)
                            self.sortedDate.removeAtIndex(self.sortedDate.indexOf() {$0 == date}!)
                        }else if(self.sortedHistory[date]![idExercise] != nil) {
                            self.sortedHistory[date]!.removeValueForKey(idExercise)
                            if(self.sortedHistory[date]?.count < 1) {
                                self.sortedHistory.removeValueForKey(date)
                                self.sortedDate.removeAtIndex(self.sortedDate.indexOf() {$0 == date}!)
                            }
                        }
                    }
                    self.decreaseCountRemoving()
                }else{
                    self.progressHUD.hide(true)
                }
                

            }
    
        
        
        
//        let removeFromHistoryStore = PFQuery(className: HISTORY_STORE)
//        removeFromHistoryStore.fromLocalDatastore()
//        removeFromHistoryStore.whereKey("id", equalTo: deleteItem.idHistory!)
//        removeFromHistoryStore.getFirstObjectInBackgroundWithBlock { (deleteObject, error) -> Void in
//            if(error != nil) {
//                if (error?.code == 101) {
//                    self.decreaseCountRemoving()
//                }
//            }
//            
//            if(deleteObject != nil) {
//                let removeFromHistoryAux = PFQuery(className: HISTORY_AUXILIARY)
//                removeFromHistoryAux.fromLocalDatastore()
//                removeFromHistoryAux.whereKey("idHistory", equalTo: deleteItem.idHistory!)
//                removeFromHistoryAux.getFirstObjectInBackgroundWithBlock { (deleteAux, error ) -> Void in
//                    
//                    if(isMassivRemoving == true) {
//                        if(self.sortedHistory[deleteObject!["date"] as! String] != nil) {
//                            if(self.sortedHistory[deleteObject!["date"] as! String]?.count < 1) {
//                                self.sortedHistory.removeValueForKey(deleteObject!["date"] as! String)
//                                self.sortedDate.removeAtIndex(self.sortedDate.indexOf() {$0 == deleteObject!["date"] as! String}!)
//                            }else if(self.sortedHistory[deleteObject!["date"] as! String]![deleteObject!["idExercise"] as! String] != nil) {
//                                self.sortedHistory[deleteObject!["date"] as! String]!.removeValueForKey(deleteObject!["idExercise"] as! String)
//                                if(self.sortedHistory[deleteObject!["date"] as! String]?.count < 1) {
//                                    self.sortedHistory.removeValueForKey(deleteObject!["date"] as! String)
//                                    self.sortedDate.removeAtIndex(self.sortedDate.indexOf() {$0 == deleteObject!["date"] as! String}!)
//                                }
//                            }
//                        }
//                    }
//                    
//                    if(error != nil) {
//                        if (error?.code == 101) {
//                            self.decreaseCountRemoving()
//                        }
//                    }
//                    
//                    if(deleteAux != nil) {
//                        let removeFromHistorySets = PFQuery(className: HISTORY_SETS)
//                        removeFromHistorySets.fromLocalDatastore()
//                        removeFromHistorySets.whereKey("id", equalTo: deleteAux!["idSet"] as! String)
//                        removeFromHistorySets.getFirstObjectInBackgroundWithBlock({ (deleteSet, error) -> Void in
//                            if(error != nil) {
//                                if (error?.code == 101) {
//                                    self.decreaseCountRemoving()
//                                }
//                            }
//                            
//                            if(deleteSet != nil) {
//                                self.countQuery = 2
//                                deleteObject?.unpinInBackgroundWithBlock({ (succsess, error ) -> Void in
//                                    
//                                    if(self.countQuery < 1) {
//                                        if(!isMassivRemoving) {
//                                            
//                                        }else {
//                                            self.decreaseCountRemoving()
//                                        }
//                                        
//                                    }else {
//                                        self.countQuery = self.countQuery - 1
//                                    }
//                                })
//                                deleteSet!.unpinInBackgroundWithBlock({ (succsess, error ) -> Void in
//                                    
//                                    if(self.countQuery < 1) {
//                                        if(!isMassivRemoving) {
//                                        }else {
//                                            self.decreaseCountRemoving()
//                                        }
//                                    }else {
//                                        self.countQuery = self.countQuery - 1
//                                    }
//                                })
//                                deleteAux!.unpinInBackgroundWithBlock({ (succsess, error ) -> Void in
//                                    
//                                    if(self.countQuery < 1) {
//                                        if(!isMassivRemoving) {
//                                            self.progressHUD.hide(true)
//                                            
//                                            //self.loadHistory()
//                                            if(self.cellStates.count == 0) {
//                                                self.emptyHistoryScreen.hidden = false;
//                                            }
//                                        }else {
//                                            self.decreaseCountRemoving()
//                                        }
//                                    }else {
//                                        self.countQuery = self.countQuery - self.countQuery
//                                    }
//                                })
//                                
//                            }
//                        })
//                    }
//                }
//                
//                
//                
//            }
//        }
        
    }
    
}

extension HistoryViewController : UITableViewDataSource,UITableViewDelegate {
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Insert:
            print(indexPath)
        case .Delete:
            let date = getDateKey(indexPath.section)
            self.progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            self.progressHUD.labelText = str_Deleting
            selectedDate = date
            if (isInner(indexPath)) {
                let externalIndex = getExternalIndex(indexPath)
                let innerIndex = getInnerIndex(externalIndex,indexPath: indexPath)
                let externalIndexPath = NSIndexPath(forRow: externalIndex, inSection: indexPath.section)
                
                selectedName = getNameKey(externalIndexPath, dateKey: date)
                selectedSetName = "\(str_Set) \(innerIndex + 1)"
                selectedSet = self.sortedHistory[selectedDate]![selectedName]![innerIndex]!
                let temp = self.sortedHistory[selectedDate]![selectedName]![innerIndex]!
                let newObject = ExerciseHistoryTemplate(id: temp.idExercise, idHistory: temp.idHistory, date: temp.date, type: temp.type, sets: temp.sets)
                if(self.sortedHistory[selectedDate]![selectedName]!.count == 1) {
                    removeSubSet(innerIndex, indexPath: indexPath)
                    removeTitle(externalIndex,indexPath: indexPath);
                    selectedName = getNameKey(NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section), dateKey: date)
                    removeDateFromTables(self.sortedHistory[selectedDate]![selectedName]!)
                    
                    return
                    //self.sortedHistory[selectedDate]!.removeAtIndex(self.sortedHistory[selectedDate]!.indexForKey(selectedName)!)
                }else {
                    self.sortedHistory[selectedDate]![selectedName]!.removeAtIndex(innerIndex)
                    removeSubSet(innerIndex, indexPath: indexPath)
                }
                
                removeObjectFromTables(newObject,isMassivRemoving: false)
                
                
                self.tableView.reloadData()
                return
            }else {
                let externalIndex = getExternalIndex(indexPath)
                //let innerIndex = getInnerIndex(externalIndex,indexPath: indexPath)
                //let externalIndexPath = NSIndexPath(forRow: externalIndex, inSection: indexPath.section)
                selectedName = getNameKey(indexPath, dateKey: date)
                removeTitle(externalIndex + 1,indexPath: indexPath);
                
                removeDateFromTables(self.sortedHistory[selectedDate]![selectedName]!)
            }
            
            //removeFromTables(self.sortedHistory[selectedDate]![selectedName]![innerIndex]!)
        default:
            return
        }
        
    }
    
    func removeTitle(exIndex:Int,indexPath:NSIndexPath) {
        var externalIndex = 0
        var trIndex = 0
        for var i = 0 ;i < cellStates.count ;i++ {
            if(indexPath.section == cellStates[i].section) {
                if(cellStates[i].inner == false) {
                    if(externalIndex == exIndex) {
                        cellStates.removeAtIndex(i)
                        if(i < cellStates.count) {
                            while(cellStates[i].inner == true){
                                cellStates.removeAtIndex(i)
                                if(i >= cellStates.count) {
                                    break;
                                }
                                if(cellStates.count == 0){
                                    break;
                                }
                                
                            }
                        }
                        
                        trIndex = i - 1
                        break
                    }
                    externalIndex = externalIndex + 1
                }
            }
        }
        if(cellStates.count == 0) {
            return
        }

        var flag = false;
        for item in cellStates {
            if(indexPath.section == item.section) {
                flag = true;
            }
        }
        var section = 0
        if(flag == false){
            
            section = indexPath.section + 1
            for index in 0...cellStates.count - 1 {
                if(section < cellStates[index].section) {
                    section = cellStates[index].section
                }
                if(section == cellStates[index].section) {
                        cellStates[index].section = cellStates[index].section - 1;
                }
                
            }
        }else {
            var ind = trIndex
            section = indexPath.section
            for index in 0...cellStates.count - 1 {
                if(section == cellStates[index].section) {
                    if(index > trIndex) {
                        if(index == 0) {
                            cellStates[index].row = 0
                        }else if(cellStates[index - 1].section == section) {
                            cellStates[index].row = cellStates[index - 1].row + 1
                        }else {
                            cellStates[index].row = 0
                        }
                        
                    }
                }
                
            }
        }
        
    }
    func removeSubSet(innerInd:Int,indexPath:NSIndexPath) {
        var inner = 0
        var trIndex = 0
        for index in 0...cellStates.count - 1 {
            if(indexPath.section == cellStates[index].section) {
                if(cellStates[index].inner == true) {
                    if(innerInd == inner) {
                        if(cellStates.count - 1 >= index + 1 ) {
                            if(cellStates[index + 1].inner == false) {
                              cellStates[index - 1].expanded = false;
                            }
                        }
                        
                        
                        cellStates.removeAtIndex(index)
                        
                        trIndex = index
                        break;
                    }else {
                        inner = inner + 1
                    }
                }
                
            }
            
        }
        inner = 0
        for index in 0...cellStates.count - 1 {
            if(indexPath.section == cellStates[index].section) {
                if(index >= trIndex) {
                    if(index == 0) {
                        cellStates[index].row = 0
                    }else if(cellStates[index - 1].section == indexPath.section) {
                        cellStates[index].row = cellStates[index - 1].row + 1
                    }else {
                        cellStates[index].row = 0
                    }

                }
            }
        }
        
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let date = getDateKey(indexPath.section)
        selectedDate = date
        
        if (isInner(indexPath)) {
            self.progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            self.progressHUD.labelText = str_UpdateH
            let externalIndex = getExternalIndex(indexPath)
            let innerIndex = getInnerIndex(externalIndex,indexPath: indexPath)
            let externalIndexPath = NSIndexPath(forRow: externalIndex, inSection: indexPath.section)
            selectedName = getNameKey(externalIndexPath, dateKey: date)
            selectedSetName = "\(str_Set) \(innerIndex + 1)"
            selectedSet = self.sortedHistory[selectedDate]![selectedName]![innerIndex]!
            if(self.selectedSet.type == "Weight") {
                performSegueWithIdentifier("setDetailWeightHistory", sender: self)
            }else {
                performSegueWithIdentifier("setDetailDistanceHistory", sender: self)
            }
            return
        }else {
            selectedName = getNameKey(indexPath, dateKey: date)
        }
        //tableView.reloadData()
        let cellState = cellStates[cellStates.indexOf(){$0.row == indexPath.row && $0.section == indexPath.section}!]
        let offsetCount = self.sortedHistory[selectedDate]![selectedName]!.count
        if(cellState.expanded == false) {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! HistoryCell
            cell.arrow.image = UIImage(named: "expanded_icon")
            offsetStates(indexPath.section, startRow: indexPath.row, countOffset: offsetCount, reverse: false)
            tableView.beginUpdates()
            var indexPathArray = [NSIndexPath]()
            var i = 1
            for _ in 0...self.sortedHistory[selectedDate]![selectedName]!.count - 1 {
                let path = NSIndexPath(forRow: indexPath.row + i , inSection: indexPath.section)
                i++
                indexPathArray.append(path)
            }
            tableView.insertRowsAtIndexPaths(indexPathArray, withRowAnimation: UITableViewRowAnimation.Bottom)
            tableView.endUpdates()
            
        }else {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! HistoryCell
            cell.arrow.image = UIImage(named: "collapsed_icon")
            offsetStates(indexPath.section, startRow: indexPath.row, countOffset: offsetCount, reverse: true)
            tableView.beginUpdates()
            var indexPathArray = [NSIndexPath]()
            var i = 1
            for _ in 0...self.sortedHistory[selectedDate]![selectedName]!.count - 1 {
                let path = NSIndexPath(forRow: indexPath.row + i , inSection: indexPath.section)
                i++
                indexPathArray.append(path)
            }
            tableView.deleteRowsAtIndexPaths(indexPathArray, withRowAnimation: UITableViewRowAnimation.Bottom)
            tableView.endUpdates()
        }
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if(self.sortedHistory == nil) {
            return 1
        }
        return self.sortedHistory.count
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(cellStates.count != 0) {
            let countRow = getCountRowInSection(section)
            
            return countRow
            
        }
        
        if(selectedDate != nil) {
            
        }
        if(self.sortedHistory == nil) {
            return 0
        }
        let date = getDateKey(section) // index 1
        
        return (self.sortedHistory[date]?.count)!
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(red: 0.94 , green: 0.94, blue: 0.94, alpha: 1);
        let headerIndexText = view as! UITableViewHeaderFooterView
        if(headerIndexText.textLabel?.text == str_Today) {
            headerIndexText.textLabel?.textColor = UIColor(rgba: "#ff4051")
        }else {
            headerIndexText.textLabel?.textColor = UIColor(rgba: "#000000")
        }
        
        //headerIndexText.textLabel?.font =  UIFont(name: "SanFranciscoText-Medium", size: 17)
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date:NSDate
        if(self.sortedHistory == nil) {
            return ""
        }
        let key = getDateKey(section)
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
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HistoryCell") as! HistoryCell
        if(self.sortedHistory.count == 0) {
            return cell
        }
        for cellState in cellStates {
            if((cellState.section == indexPath.section)&&(cellState.row == indexPath.row)&&(cellState.inner == true)) {
                let cell = tableView.dequeueReusableCellWithIdentifier("HistoryExpandedCell") as! HistoryExpandedCell
                let externalIndex = getExternalIndex(indexPath)
                let innerIndex = getInnerIndex(externalIndex,indexPath: indexPath)
                
                cell.setName.text = " \(str_Set) \(innerIndex + 1)"
                
                let date = getDateKey(indexPath.section)
                selectedDate = date
                let externalIndexPath = NSIndexPath(forRow: externalIndex, inSection: indexPath.section)
                selectedName = getNameKey(externalIndexPath, dateKey: date)
                
                var type = ""
                if(self.sortedHistory[selectedDate]![selectedName]![innerIndex]!.type == "Weight") {
                    type = Settings.sharedInstance.currentWightUnit
                }else {
                    type = Settings.sharedInstance.currentDistanceUnit
                }
                //cell.setParameters.text = "\(leftValue) x \(rightValue) \(type)"
                
                if(self.sortedHistory[selectedDate]![selectedName]![innerIndex]!.type != "Weight") {
                    let timeValue = self.sortedHistory[selectedDate]![selectedName]![innerIndex]!.sets![0].rightValue!.characters.split{$0 == ":"}.map(String.init)
                    var timeStr = "\(timeValue[0]):\(timeValue[1]):\(timeValue[2])"
                    if((timeValue[0] == "0") && (timeValue[2] == "0") && (timeValue[2] == "0") ) {
                        timeStr = ""
                    }
                    
                    let distanceValue = self.sortedHistory[selectedDate]![selectedName]![innerIndex]!.sets![0].leftValue!.characters.split{$0 == ":"}.map(String.init)
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
                    
                    let weightValue = self.sortedHistory[selectedDate]![selectedName]![innerIndex]!.sets![0].rightValue!.characters.split{$0 == ":"}.map(String.init)
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
                    cell.setParameters.text = "\(self.sortedHistory[selectedDate]![selectedName]![innerIndex]!.sets![0].leftValue) x \(rightValue) " + type
                    return cell
                }
                
            }
        }
        if(self.sortedHistory == nil) {
            return cell
        }
        
        
        let date = getDateKey(indexPath.section)
        selectedDate = date
        selectedName = getNameKey(indexPath, dateKey: date)
        if(self.sortedHistory[selectedDate]![selectedName]!.count == 0) {
            return cell
        }
        cell.exerciseLabel.text = ""
        getExerciseName(self.sortedHistory[selectedDate]![selectedName]![0]!.idExercise!,label: cell.exerciseLabel)
        
        if(self.sortedHistory[selectedDate]![selectedName]![0]!.type == "Weight") {
            let count = self.sortedHistory[selectedDate]![selectedName]!.count
            //cell.exerciseLabel.text = name
            if( NSLocale.preferredLanguages()[0] != "ru") {
                if(count == 1) {
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)"
                }else {
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)s"
                }
            }else {
                
                if(count == 1) {
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)"
                }else if(count > 10) && (count < 20) {
                     cell.setCount.text = "\(count) \(str_Set.lowercaseString)ов"
                }else if(((count % 10) == 2)||((count % 10) == 3)||((count % 10) == 4)){
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)а"
                }else if((count % 10) > 4) {
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)ов"
                }else if((count % 10) == 0){
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)ов"
                }else if((count % 10) == 1){
                    cell.setCount.text = "\(count) \(str_Set.lowercaseString)"
                }
            }
            
            
        }else {
            self.summHour = 0
            self.summMin = 0
            self.summSec = 0
            self.summDistance = 0
            countTime(self.sortedHistory[selectedDate]![selectedName]!)
            //cell.exerciseLabel.text = name
            let hour = self.summHour < 10 ? "0\(self.summHour)" : "\(self.summHour)"
            let min = self.summMin < 10 ? "0\(self.summMin)" : "\(self.summMin)"
            let sec = self.summSec < 10 ? "0\(self.summSec)" : "\(self.summSec)"
            cell.setCount.text = "\(self.summDistance) \(Settings.sharedInstance.currentDistanceUnit), \(hour):\(min):\(sec)"
        }
        
        cell.arrow.image = UIImage(named: "collapsed_icon")
        
        
        return cell
    }
    
    func countTime(array:[ExerciseHistoryTemplate!]) {
        for item in array {
            let distance = item.sets![0].leftValue.characters.split{$0 == ":"}.map(String.init)
            let convertDistance:String!
            if(distance[1] == str_km) {
                if(distance[1] == Settings.sharedInstance.currentDistanceUnit) {
                    convertDistance = distance[0]
                }else {
                    convertDistance = Settings.sharedInstance.convertKmToMil(distance[0], toMil: true)
                }
            }else {
                if(distance[1] == Settings.sharedInstance.currentDistanceUnit) {
                    convertDistance = distance[0]
                }else {
                    convertDistance = Settings.sharedInstance.convertKmToMil(distance[0], toMil: false)
                }
            }
            
            
            self.summDistance = self.summDistance + Double(convertDistance)!
            let time =  item.sets![0].rightValue.characters.split{$0 == ":"}.map(String.init)
            self.summHour = self.summHour + Int(time[0])!
            self.summMin = self.summMin + Int(time[1])!
            self.summSec = self.summSec + Int(time[2])!
            if(self.summSec > 59) {
                self.summMin = self.summMin + 1
                self.summSec = self.summSec - 60
            }
            if(self.summMin > 59) {
                self.summHour = self.summHour + 1
                self.summMin = self.summMin - 60
            }
            
            
            
            
        }
    }
}
