//
//  File.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/6/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation


class ExerciseTemplate : NSObject, NSCopying {
    var id:String!
    var name:String!
    var checked:Bool!
    var used:Int!
    var custom:Bool!
    var priority:Int?
    var type:String!
    init (id:String,name:String,checked:Bool,custom:Bool,used:Int,type:String!,priority:Int?) {
        self.id = id
        self.name = name
        self.checked = checked
        self.type = type
        self.custom = custom
        self.used = used
        self.priority = priority
    }
    override init() {
        self.name = ""
        self.checked = false
        self.custom = false
        self.used = 0
    }
     func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = ExerciseTemplate(id: id, name: name, checked: checked,custom:custom,used:used,type:type,priority:priority)
        return copy
    }
}

