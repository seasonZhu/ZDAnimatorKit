//
//  AnimationSmoothEffect.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class AnimationSmoothEffect: AnimationBasicEffect {
    ///  可重写UIViewControllerAnimatedTransitioning
}

extension AnimationSmoothEffect {
    override func transitionAnimationWithForward(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerViewColor = transitionContext.containerView.backgroundColor
        transitionContext.containerView.backgroundColor = UIColor.white
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        transitionContext.containerView.addSubview(fromView)
        transitionContext.containerView.addSubview(toView)
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        toView.frame = CGRect(x: window.frame.width, y: 0, width: window.frame.width, height: window.frame.height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toView.frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.height)
        }) { (_) in
            transitionContext.containerView.backgroundColor = containerViewColor
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    
    override func transitionAnimationWithBack(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerViewColor = transitionContext.containerView.backgroundColor
        transitionContext.containerView.backgroundColor = UIColor.white
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        transitionContext.containerView.addSubview(fromView)
        transitionContext.containerView.addSubview(toView)
        
        guard let fromSnapShotView = fromView.snapshotView(afterScreenUpdates: false) else {
            return
        }
        
        transitionContext.containerView.addSubview(fromSnapShotView)
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        fromSnapShotView.frame = CGRect(x: 0, y: 0, width: window.frame.width, height: window.frame.height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromSnapShotView.frame = CGRect(x: window.frame.width, y: 0, width: window.frame.width, height: window.frame.height)
        }) { (_) in
            transitionContext.containerView.backgroundColor = containerViewColor
            fromSnapShotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
