//
//  UIViewController+SwizzleMethod.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/14.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

extension UIViewController {
    public static func swizzleMethod() {
        DispatchQueue.once(token: "com.season.zhu.ZDAnimatorDemo") {
            let originalSelector = Selector.sysFunc
            let swizzledSelector = Selector.zdFunc
            changeMethod(originalSelector, swizzledSelector, self)
        }
    }
    
    private static func changeMethod(_ original:Selector,_ swizzled:Selector,_ object: AnyClass) -> () {
        
        let originalMethod = class_getInstanceMethod(object, original)
        let swizzledMethod = class_getInstanceMethod(object, swizzled)
        
        let didAddMethod: Bool = class_addMethod(object, original, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        if didAddMethod {
            class_replaceMethod(object, swizzled, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!)
        }
    }
    
    @objc func zdViewWillAppear(_ animated: Bool) {
        print("交换了viewWillAppear的方法")
        
        self.navigationController?.delegate = animationTransition
        
        DispatchQueue.main.async {
            self.zdViewWillAppear(animated)
        }
    }
}

fileprivate extension Selector {
    
    static let sysFunc = #selector(UIViewController.viewWillAppear(_:))
    static let zdFunc = #selector(UIViewController.zdViewWillAppear(_:))
}

fileprivate extension DispatchQueue {
    private static var onceTracker = [String]()
    
    fileprivate class func once(token: String, block:() -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if onceTracker.contains(token) {
            return
        }
        onceTracker.append(token)
        block()
    }
}

