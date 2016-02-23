//
//  WorkoutsTemplate.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/9/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation
import Parse
class WorkoutTemplate {
    var workoutId:String!
    var workoutName:String!
    
    init(id:String!,name:String!) {
        self.workoutId = id
        self.workoutName = name
    }
}
