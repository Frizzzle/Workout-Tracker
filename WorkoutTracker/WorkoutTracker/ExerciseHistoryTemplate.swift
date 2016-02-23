//
//  ExerciseHistoryTemplate.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/21/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation


class ExerciseHistoryTemplate {
    var idExercise:String?
    var idHistory:String?
    var date:NSDate?
    var type:String?
    var sets:[SetTemplate]?
    
    init (id:String?,idHistory:String?,date:NSDate?,type:String?,sets:[SetTemplate]?) {
        self.idExercise = id
        self.idHistory = idHistory
        self.date = date
        self.type = type
        self.sets = sets
    }
}