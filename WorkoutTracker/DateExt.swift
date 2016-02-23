//
//  DateExt.swift
//  WorkoutTracker
//
//  Created by Koctya on 17.11.15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

extension NSDate {
    class func toString(date:NSDate) -> String{
        let formater = NSDateFormatter()
        formater.dateFormat = "dd.MM.yy"
        return formater.stringFromDate(date)
    }
    
    class func date(dateString:String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy"
        return dateFormatter.dateFromString(dateString)!
    }
    
    class func yesterdayMy() -> NSDate {
        let day = NSDate.today - 1.days

        return day
    }
    
    func isGreaterThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
        {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    
    
    func isLessThanDate(dateToCompare : NSDate) -> Bool
    {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
        {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
    
    

    
    
    
   
    
}
