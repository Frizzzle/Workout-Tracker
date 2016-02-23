//
//  UserExercises.swift
//  WorkoutTracker
//
//  Created by Koctya on 12/10/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//
import UIKit
import Parse
let USER_EXERCISES_CLASS = "UserExercises"
class UserExercisesManager {
    static let sharedInstance = UserExercisesManager()
    var userExercises = [UserExerciseModel]()
    
    init() {
        loadHistory()
    }
    
    func isExerciseEmpty(idExercise:String) -> Bool{
        for item in userExercises {
            if(item.idExercise == idExercise) {
                return false
            }
        }
        return true
    }
    
    func getSetById(idRecord:String) -> PFObject? {
        for item in userExercises {
            if (item.idRecord == idRecord) {
                let retObject = PFObject(className: "a")
                retObject["leftValue"] = item.leftValue
                retObject["rightValue"] = item.rightValue
                return retObject
            }
        }
        return nil
    }
    
    func addRecord(idExercise:String,date:NSDate,idWorkout:String,type:String,leftValue:String,rightValue:String,onFinish:(() -> Void)?) {
        
        let newRecord = PFObject(className: USER_EXERCISES_CLASS)
        newRecord["idExercise"] = idExercise
        newRecord["idWorkout"] = idWorkout
        newRecord["date"] = NSDate.toString(date)
        newRecord["type"] = type
        newRecord["leftValue"] = leftValue
        newRecord["rightValue"] = rightValue
        newRecord.ownSaveEventually { (sur, error ) -> Void in
            newRecord.pinInBackground()
            self.userExercises.append(UserExerciseModel(id: idExercise, idWorkout: idWorkout, date: date, type: type, leftValue: leftValue, rightValue: rightValue,idRecord: newRecord["id"] as! String))
            onFinish!()
        }
        
    }
    func resetByDefault(onSuccess:(() -> Void)?) {
        userExercises.removeAll()
        let  remQ = PFQuery(className:USER_EXERCISES_CLASS )
        remQ.fromLocalDatastore()
        remQ.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
            PFObject.unpinAllInBackground(objects, block: { (success, ErrorType) -> Void in
                onSuccess!()
            })
        }
    }
    
    func deleteExercise(idRecord:String ,onFinish:(() -> Void)?) {
        var index = 0
        for var i = 0;i < self.userExercises.count;i++ {
            if(self.userExercises[i].idRecord == idRecord) {
                index = i
                let removeQuery = PFQuery(className: USER_EXERCISES_CLASS)
                removeQuery.fromLocalDatastore()
                removeQuery.whereKey("id", equalTo: idRecord)
                removeQuery.getFirstObjectInBackgroundWithBlock({ (object , error ) -> Void in
                    if(object != nil) {
                        object!.unpinInBackground()
                        self.userExercises.removeAtIndex(index)
                        onFinish!()
                    }
                })
                break;
            }
        }
    }
    
    func deleteExerciseHistory(idExercise:String,onFinish:(() -> Void)?) {
        for var i = 0;i < self.userExercises.count;i++ {
            if(self.userExercises[i].idExercise == idExercise) {
                self.userExercises.removeAtIndex(i)
                i = i - 1
            }
        }
        let removeQuery = PFQuery(className: USER_EXERCISES_CLASS)
        removeQuery.fromLocalDatastore()
        removeQuery.whereKey("idExercise", equalTo: idExercise)
        removeQuery.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
            PFObject.unpinAllInBackground(objects)
            onFinish!()
        }
    }
    func deleteExerciseHistoryWithDate(idExercise:String,date:NSDate,onFinish:(() -> Void)?) {
        for var i = 0;i < self.userExercises.count;i++ {
            if((self.userExercises[i].idExercise == idExercise)&&(self.userExercises[i].date == date)) {
                self.userExercises.removeAtIndex(i)
                i = i - 1
            }
        }
        let removeQuery = PFQuery(className: USER_EXERCISES_CLASS)
        removeQuery.fromLocalDatastore()
        removeQuery.whereKey("idExercise", equalTo: idExercise)
        removeQuery.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
            PFObject.unpinAllInBackground(objects)
            onFinish!()
        }
    }
    
    func updateRecord(idRecord:String,date:NSDate,leftValue:String,rightValue:String) {
        for item in userExercises {
            if(item.idRecord == idRecord) {
                item.date = date
                item.leftValue = leftValue
                item.rightValue = rightValue
                let updateQuery = PFQuery(className: USER_EXERCISES_CLASS)
                updateQuery.fromLocalDatastore()
                updateQuery.whereKey("id", equalTo: idRecord)
                updateQuery.getFirstObjectInBackgroundWithBlock({ (object , error ) -> Void in
                    if(object != nil) {
                        object!["date"] = NSDate.toString(date)
                        object!["leftValue"] = leftValue
                        object!["rightValue"] = rightValue
                        object!.pinInBackground()
                    }
                })
            }
        }
    
    }
    
    func getExerciseHistory(exerciseId:String,onSuccess:(([ExerciseHistoryTemplate]) -> Void)?) {
        var exercises = [UserExerciseModel]()
        for exerc in userExercises {
            if(exerc.idExercise == exerciseId) {
                exercises.append(exerc)
            }
        }
        var returnValue = [ExerciseHistoryTemplate]()
        for item in exercises {
            returnValue.append(ExerciseHistoryTemplate(id: item.idExercise, idHistory: item.idWorkout, date: item.date, type: item.type, sets: [SetTemplate(idSet: item.idRecord, leftValue: item.leftValue, rightValue: item.rightValue)]))
        }
        onSuccess!(returnValue)
    }
    func getHistory(onSuccess:(([ExerciseHistoryTemplate]) -> Void)?) {
        var returnValue = [ExerciseHistoryTemplate]()
        for item in self.userExercises {
            returnValue.append(ExerciseHistoryTemplate(id: item.idExercise, idHistory: item.idWorkout, date: item.date, type: item.type, sets: [SetTemplate(idSet: item.idRecord, leftValue: item.leftValue, rightValue: item.rightValue)]))
        }
        onSuccess!(returnValue)
    }
    
    
    
    func loadHistory() {
        let history = PFQuery(className: USER_EXERCISES_CLASS)
        history.fromLocalDatastore()
        history.findObjectsInBackgroundWithBlock { (historyObjects, error ) -> Void in
            for object in historyObjects! {
                let idExercise = object["idExercise"] as! String
                let idWorkout = object["idWorkout"] as! String
                let date =      object["date"] as! String
                let type =      object["type"] as! String
                let leftValue = object["leftValue"] as! String
                let rightValue = object["rightValue"] as! String
                let idRecord = object["id"] as! String
                self.userExercises.append(UserExerciseModel(id: idExercise, idWorkout: idWorkout, date: NSDate.date(date), type: type, leftValue: leftValue, rightValue: rightValue,idRecord:idRecord))
            }
        }
    }
    
}

