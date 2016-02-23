//
//  GeneratorID.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/16/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation
import Parse
 
class GeneratorID {
    static func getObjectID(className:String!) -> String! {
        let getQuery = PFQuery(className: className)
        getQuery.fromLocalDatastore()
       // let objectId =
        //getQuery.whereKey("objectId", equalTo: <#T##AnyObject#>)
        
        return ""
    }
    
}

extension PFObject {
    public func ownSaveEventually(callback: PFBooleanResultBlock?) {
        generate(callback)
    }
    
    func generate(callback: PFBooleanResultBlock?){
        let id = generateID()
        let query = PFQuery(className: self.parseClassName)
        query.fromLocalDatastore()
        query.whereKey("id", equalTo: id)
        query.findObjectsInBackgroundWithBlock { (objects, error ) -> Void in
            if(objects?.count == 0) {
                self["id"] = id;
                let yer = "\(NSDate().year)\(NSDate().month)\(NSDate().day)"
                let seconds = Int(NSDate().seconds) < 10 ? "0\(Int(NSDate().seconds))" : "\(Int(NSDate().seconds))"
                let time = "\(yer)\(NSDate().hours)\(NSDate().minutes)\(seconds)"
                self["unicDate"] = time;
                callback!(true,nil)
            }else {
                self.generate(callback);
            }
        }
    }
    
    func generateID() -> String {
        let s = NSMutableData(length: 6)
        SecRandomCopyBytes(kSecRandomDefault, Int(s!.length), UnsafeMutablePointer<UInt8>(s!.mutableBytes))
        let base64str = s!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        return base64str
    }
}