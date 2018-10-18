//
//  ThreadHelper.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

extension DispatchQueue {
    func safeAsync(_ block: @escaping () -> ()) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        }else {
            async {
                block()
            }
        }
    }
}
