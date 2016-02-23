//
//  SetTemplate.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/21/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation


class SetTemplate {
    var idSet:String!
    var leftValue:String!
    var rightValue:String!
    
    init(idSet:String,leftValue:String,rightValue:String) {
        self.idSet = idSet
        self.leftValue = leftValue
        self.rightValue = rightValue
    }
}