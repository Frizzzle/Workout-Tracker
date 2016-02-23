//
//  TabBarViewController.swift
//  WorkoutTracker
//
//  Created by Koctya Bondar on 10/1/15.
//  Copyright © 2015 Koctya Bondar. All rights reserved.
//

import Foundation
import UIKit

class TabBarViewController: UITabBarController {
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        switch (item.title) {
        case str_Workouts? :
            self.navigationController?.navigationBar.topItem?.title = str_Workouts
            break;
        case str_History? :
            self.navigationController?.navigationBar.topItem?.title = str_History
            break;
        case str_Settings? :
            self.navigationController?.navigationBar.topItem?.title = str_Settings
            break;
        default:
            break;
        }
    }
}
