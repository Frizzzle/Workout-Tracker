//
//  Exercise.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/9/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation

class Exercise {
    var objectId:String!
    var exerciseName:String!
    var usedCount:Int!
    var isCustom:Bool!
    var type:String!
    
    init(id:String!,name:String,usedCount:Int!,type:String,isCustom:Bool!) {
        self.objectId = id
        self.exerciseName = name
        self.type = type
        self.usedCount = usedCount
        self.isCustom = isCustom

    }
}