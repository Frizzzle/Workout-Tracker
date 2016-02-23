//
//  UserExerciseModel.swift
//  WorkoutTracker
//
//  Created by Koctya on 12/10/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation

class UserExerciseModel {
    var idRecord:String!
    var idExercise:String?
    var idWorkout:String?
    var date:NSDate?
    var type:String?
    var leftValue:String!
    var rightValue:String!
    
    init (id:String?,idWorkout:String?,date:NSDate?,type:String?,leftValue:String,rightValue:String,idRecord:String) {
        self.idExercise = id
        self.idWorkout = idWorkout
        self.date = date
        self.type = type
        self.leftValue = leftValue
        self.rightValue = rightValue
        self.idRecord = idRecord
    }
}