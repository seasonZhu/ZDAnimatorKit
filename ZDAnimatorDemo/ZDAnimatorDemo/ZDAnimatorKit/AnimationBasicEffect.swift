//
//  AnimationBasicEffect.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class AnimationBasicEffect: NSObject {
    var isBack: Bool
    
    init(isBack: Bool) {
        self.isBack = isBack
        super.init()
    }
}

extension AnimationBasicEffect: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return kAnimationTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isBack {
            transitionAnimationWithBack(using: transitionContext)
        }else {
            transitionAnimationWithForward(using: transitionContext)
        }
    }
}

// MARK: - IAnimationAction 该协议子类要重写 所以根据Xcode提示必须要加上@objc前缀
extension AnimationBasicEffect: IAnimationAction {
    @objc func transitionAnimationWithForward(using transitionContext: UIViewControllerContextTransitioning) {
        
    }
    
    @objc func transitionAnimationWithBack(using transitionContext: UIViewControllerContextTransitioning) {
        
    }
}
