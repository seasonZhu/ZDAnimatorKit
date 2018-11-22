//
//  Notifications.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/22.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

extension Notification.Name {
    public struct Task {
        public static let DidResume = Notification.Name(rawValue: "org.alamofire.notification.name.task.didResume")
        
        public static let DidSuspend = Notification.Name(rawValue: "org.alamofire.notification.name.task.didSuspend")
        
        public static let DidCancel = Notification.Name(rawValue: "org.alamofire.notification.name.task.didCancel")
        
        public static let DidComplete = Notification.Name(rawValue: "org.alamofire.notification.name.task.didComplete")
    }
}

extension Notification {
    public struct Key {
        public static let Task = "org.alamofire.notification.key.task"
        
        public static let ResponseData = "org.alamofire.notification.key.responseData"
    }
}
