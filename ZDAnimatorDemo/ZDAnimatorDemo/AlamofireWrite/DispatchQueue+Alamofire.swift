//
//  DispatchQueue+Alamofire.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/22.
//  Copyright © 2018 season. All rights reserved.
//

import Dispatch
import Foundation

extension DispatchQueue {
    /*
     其实我唯一想说的是的直接用static let也是可以 为啥这里要使用 只读属性
     static let userInteractive = DispatchQueue.global(qos: .userInteractive)
     qos 表示设置队列的优先级
     
     关于qos的解释
     .userInteractive 需要用户交互的，优先级最高，和主线程一样
     .userInitiated 即将需要，用户期望优先级，优先级高比较高
     .default 默认优先级
     .utility 需要执行一段时间后，再通知用户，优先级低
     *.background 后台执行的，优先级比较低
     *.unspecified 不指定优先级，最低
     */
    static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }
    
}
