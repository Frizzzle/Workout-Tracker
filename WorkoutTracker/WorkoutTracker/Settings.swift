//
//  DataStore.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/7/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation
import Parse
let SETTING_STORE = "SettingsStore"
let TYPE_WEIGHT = 0
let TYPE_DURATION = 1
let TYPE_DIST = 2
let TYPE_REPS = 3

class Settings {
    static let sharedInstance = Settings()
    
    var selectedWeight:String!
    var selectedDistance:String!
    var selectedDuration:String!
    var selectedReps:String!
    
    init() {
        loadFromLocal()
        let settingQuery = PFQuery(className: SETTING_STORE)
        settingQuery.fromLocalDatastore()
        do {
            let setting:PFObject? = try settingQuery.getFirstObject()
            if(setting != nil) {
                currentDistanceUnit = setting!["distanceUnit"] as! String
                currentWightUnit = setting!["weightUnit"] as! String
                isResetState = false

            }
        }catch {
            currentDistanceUnit = str_km
            currentWightUnit = str_kg
            isResetState = false
            self.saveSettingState(currentDistanceUnit, weightUnit: currentWightUnit)
        }
        
    }
    
    func saveInLocal(value:String,type:Int) {
        switch(type) {
        case TYPE_WEIGHT :
            NSUserDefaults.standardUserDefaults().setObject("selectedWeight", forKey: value)
            NSUserDefaults.standardUserDefaults().synchronize()
            selectedWeight = value
            break
        case TYPE_DURATION :
            NSUserDefaults.standardUserDefaults().setObject("selectedDuration", forKey: value)
            NSUserDefaults.standardUserDefaults().synchronize()
            selectedDuration = value
            break
        case TYPE_DIST :
            NSUserDefaults.standardUserDefaults().setObject("selectedDistance", forKey: value)
            NSUserDefaults.standardUserDefaults().synchronize()
            selectedDistance = value
            break
        case TYPE_REPS :
            NSUserDefaults.standardUserDefaults().setObject("selectedReps", forKey: value)
            NSUserDefaults.standardUserDefaults().synchronize()
            selectedReps = value
            break
        default:
            break
        }
    }
    
    func loadFromLocal() {
        let defaults = NSUserDefaults.standardUserDefaults()
        selectedWeight = defaults.stringForKey("selectedWeight")
        selectedDuration = defaults.stringForKey("selectedDuration")
        selectedDistance = defaults.stringForKey("selectedDistance")
        selectedReps = defaults.stringForKey("selectedReps")
        if(selectedWeight == nil) {
            selectedWeight = "0:kg"
        }
        if(selectedReps == nil) {
            selectedReps = "1"
        }
        if(selectedDuration == nil) {
            selectedDuration = "0:0:0"
        }
        if(selectedDistance == nil) {
            selectedDistance = "0:km"
        }
    }
    
    func saveSettingState(distanceUnit:String,weightUnit:String) {
        let settingQuery = PFQuery(className: SETTING_STORE)
        settingQuery.fromLocalDatastore()
        do {
            let setting:PFObject? = try settingQuery.getFirstObject()
            if(setting != nil) {
                if(distanceUnit.isEmpty != true) {
                    setting!["distanceUnit"] = distanceUnit
                    currentDistanceUnit = distanceUnit
                }
                if(weightUnit.isEmpty != true) {
                    setting!["weightUnit"] = weightUnit
                    currentWightUnit = weightUnit
                }
                
                
                try setting!.pin()
            }
        }catch {
            let settingObject = PFObject(className: SETTING_STORE)
            if(distanceUnit.isEmpty != true) {
                settingObject["distanceUnit"] = distanceUnit
                currentDistanceUnit = distanceUnit
                
            }
            if(weightUnit.isEmpty != true) {
                settingObject["weightUnit"] = weightUnit
                currentWightUnit = weightUnit
            }
            do {
                try settingObject.pin()
            }catch {
                
            }
  
        }
    }
    
    func convertKgToPd(fromValue:String,toPd:Bool!) -> String {
        let fromD = Double(fromValue)

        if(fromD == 0) {
            return "0"
        }
        if(toPd == true) {
            let val = fromD! * 2.20462
            
            return String(format: "%.2f", val)// "\(val)"
        }else {
            let val = fromD! / 2.20462
            return String(format: "%.2f", val)
        }
        
    }
    
    func convertKmToMil(fromValue:String,toMil:Bool!) -> String {
        let fromD = Double(fromValue)
        
        if(fromD == 0) {
            return "0"
        }
        if(toMil == true) {
            let val = fromD! * 0.621371
            return String(format: "%.2f", val)
        }else {
            let val = fromD! / 0.621371
            return String(format: "%.2f", val)
        }
        
    }
    
    var currentWightUnit:String!
    var currentDistanceUnit:String!
    
    var isResetState:Bool!
    
}