//
//  ExerciseManager.swift
//  WorkoutTracker
//
//  Created by Koctya on 12/10/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import UIKit
import Parse

class ExerciseManager {
    static let sharedInstance = ExerciseManager()
    var exercises = [Exercise]()
    var state:Int!
    var count:Int!
    
    
    init() {
        count = -1
        state = EXRS_STATE_NOT_LOAD
        loadExercisesFromDB()
    }
    func resetByDefault(onSuccess:(() -> Void)?) {
        exercises.removeAll()
        let  remQ = PFQuery(className: EXERCISE_STORE)
        remQ.fromLocalDatastore()
        remQ.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
            PFObject.unpinAllInBackground(objects, block: { (success, ErrorType) -> Void in
                onSuccess!()
            })
        }
    }
    
    func firstLoadExercises(created:(([String]) -> Void)?) {
        var objects = [PFObject]()
        var returnedId = [String]()
        for index in 0...defaultExercises.count - 1 {
            var type = ""
            if index < DEFOULT_WEIGHT_COUNT  {
                type = "Weight"
            }else {
                type = "Distance"
            }
            switch(defaultExercises[index]) {
            case str_8 :
                objects.append(createDefRecord(defaultExercises[index],type: type))
                break
            case str_1 :
                objects.append(createDefRecord(defaultExercises[index],type: type))
                break
            case str_9 :
                objects.append(createDefRecord(defaultExercises[index],type: type))
                break
            case str_42 :
                objects.append(createDefRecord(defaultExercises[index],type: type))
                break
            case str_92 :
                objects.append(createDefRecord(defaultExercises[index],type: type))
                break

            default :
                let item = createDefRecord(defaultExercises[index],type: type)
                item.ownSaveEventually({ (success, error ) -> Void in
                    item.pinInBackground()
                    self.exercises.append(Exercise(id: item["id"] as! String, name: item["name"] as! String, usedCount: item["usedCount"] as! Int, type: item["type"] as! String, isCustom: item["isCustom"] as! Bool))
                })

                break
            }
        }
        var countQ = objects.count
        for item in objects {
            item.ownSaveEventually({ (success, error ) -> Void in
                item.pinInBackground()
                returnedId.append(item["id"] as! String)
                self.exercises.append(Exercise(id: item["id"] as! String, name: item["name"] as! String, usedCount: item["usedCount"] as! Int, type: item["type"] as! String, isCustom: item["isCustom"] as! Bool))
                countQ = countQ - 1
                if(countQ == 0) {
                    self.state = EXRS_STATE_LOADED
                    created!(returnedId)
                }
            })
        }
        
        
    }
    func createDefRecord(name:String,type:String) -> PFObject {
        let defObject = PFObject(className: EXERCISE_STORE)
        defObject["name"] = name
        defObject["usedCount"] = 0
        defObject["isCustom"] = false
        defObject["type"] = type
        return defObject
    }
    
    
    func renameAll() {
        let renameDefaultQuery = PFQuery(className: EXERCISE_STORE)
        renameDefaultQuery.fromLocalDatastore()
        renameDefaultQuery.whereKey("isCustom", equalTo: false)
        renameDefaultQuery.findObjectsInBackgroundWithBlock({ (exercises , error ) -> Void in
            if(exercises!.count == 0) {
                return
            }
            for index in 0...exercises!.count - 1 {
                exercises?[index]["name"] = defaultExercises[index]
                exercises?[index].pinInBackground()
            }
        })
    }
    
    func removeAll() {
        exercises.removeAll()
        state = EXRS_STATE_NOT_LOAD
    }
    
    func loadExercise() {
        loadExercisesFromDB()
    }
    
    func getExercises() -> [Exercise] {
        while(true) {
            if(state == EXRS_STATE_LOADED) {
                return exercises
            }
        }
        return [Exercise]()
    }
    
    func getExercisesById(id:[String]) -> [Exercise] {
        var returnExercises = [Exercise]()
        let exercisesLoaded = getExercises()
        for exer in exercisesLoaded {
            if(id.contains(exer.objectId)) {
                returnExercises.append(exer)
            }
        }
        return returnExercises
    }
    
    func decreaseExerciseCount(id:String) {
        for exer in exercises {
            if(exer.objectId == id) {
                exer.usedCount = exer.usedCount - 1
            }
        }
        let isUsedQuery = PFQuery(className: EXERCISE_STORE)
        isUsedQuery.fromLocalDatastore()
        isUsedQuery.whereKey("id", equalTo: id)
        isUsedQuery.getFirstObjectInBackgroundWithBlock({ (usedItem, error ) -> Void in
            if(usedItem != nil) {
                if(usedItem?["usedCount"] as! Int - 1 < 0) {
                   usedItem?["usedCount"] = 0
                }else {
                   usedItem?["usedCount"] = usedItem?["usedCount"] as! Int - 1
                }
                
                usedItem?.pinInBackground()
                
                
            }
        })
    }
    
    func createNewExercise(newItem:Exercise,exist:(() -> Void)?,success:(() -> Void)?) {
        let successs = success
        if(exercises.contains() {$0.exerciseName == newItem.exerciseName } == true) {
            exist!()
        }else {
            let item = PFObject(className: EXERCISE_STORE)
            item["name"] = newItem.exerciseName
            item["usedCount"] = 0
            item["isCustom"] = true
            item["type"] = newItem.type
            item.ownSaveEventually({ (success, error ) -> Void in
                item.pinInBackground()
                newItem.objectId = item["id"] as! String
                self.exercises.append(Exercise(id: item["id"] as! String, name: item["name"] as! String, usedCount: item["usedCount"] as! Int, type: item["type"] as! String, isCustom: item["isCustom"] as! Bool))
                successs!()
            })
            
        }
    }
    func isUnicName(name:String) -> Bool {
        if(exercises.contains() {$0.exerciseName == name } == true) {
            return false
        }else {
            return true
        }
    }
    func renameExercise(name:String,id:String) {
        let exercise = exercises[exercises.indexOf() {$0.objectId == id }!]
        exercise.exerciseName = name
        
        let exerciseStoreQuery = PFQuery(className: EXERCISE_STORE)
        exerciseStoreQuery.fromLocalDatastore()
        exerciseStoreQuery.whereKey("id", equalTo: exercise.objectId)
        exerciseStoreQuery.getFirstObjectInBackgroundWithBlock { (object, error ) -> Void in
            if(object != nil) {
                object!["name"] = name
                object!.pinInBackground()
            }
        }
    }
    
    func increaseExerciseCount(id:String) {
        for exer in exercises {
            if(exer.objectId == id) {
                exer.usedCount = exer.usedCount + 1
            }
        }
        let isUsedQuery = PFQuery(className: EXERCISE_STORE)
        isUsedQuery.fromLocalDatastore()
        isUsedQuery.whereKey("id", equalTo: id)
        isUsedQuery.getFirstObjectInBackgroundWithBlock({ (usedItem, error ) -> Void in
            if(usedItem != nil) {
                usedItem?["usedCount"] = usedItem?["usedCount"] as! Int + 1
                usedItem?.pinInBackground()
                
                
            }
        })
    }
    
    func loadExercisesFromDB() {
        state = EXRS_STATE_IS_LOADING
        
        let customQuery = PFQuery(className: EXERCISE_STORE)
        customQuery.fromLocalDatastore()
        customQuery.findObjectsInBackgroundWithBlock { (objects_ex, error ) -> Void in
            if(objects_ex?.count != 0) {
                for item in objects_ex! {
                    self.exercises.append(Exercise(id: item["id"] as! String, name: item["name"] as! String, usedCount: item["usedCount"] as! Int, type: item["type"] as! String, isCustom: item["isCustom"] as! Bool))
                }
                self.state = EXRS_STATE_LOADED
                return
            }
            self.state = EXRS_STATE_NOT_LOAD
            
            
        }
    }
}
