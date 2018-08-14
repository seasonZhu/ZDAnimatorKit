//
//  AnimationTikTokEffect.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class AnimationTikTokEffect: AnimationBasicEffect {
    ///  可重写UIViewControllerAnimatedTransitioning
}

// MARK: - 这个动画有Back问题 有待解决
extension AnimationTikTokEffect {
    override func transitionAnimationWithForward(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerViewColor = transitionContext.containerView.backgroundColor
        transitionContext.containerView.backgroundColor = UIColor.white
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        guard let fromSnapShotView = fromView.snapshotView(afterScreenUpdates: false) else {
            return
        }
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        transitionContext.containerView.addSubview(fromSnapShotView)
        transitionContext.containerView.addSubview(toView)
        
        toView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: window.frame.height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toView.frame = CGRect(x: 0, y: window.frame.height / 3, width: window.frame.width, height: window.frame.height)
        }) { (_) in
            transitionContext.containerView.backgroundColor = containerViewColor
            //fromSnapShotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    override func transitionAnimationWithBack(using transitionContext: UIViewControllerContextTransitioning) {
        //transitionAnimationWithForward(using: transitionContext)
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!

        let containerViewColor = transitionContext.containerView.backgroundColor
        transitionContext.containerView.backgroundColor = UIColor.white

        let fromView = fromVC.view!
        let toView = toVC.view!

        guard let fromSnapShotView = fromView.snapshotView(afterScreenUpdates: false) else {
            return
        }

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        transitionContext.containerView.addSubview(fromSnapShotView)
        transitionContext.containerView.addSubview(toView)

        fromView.frame = CGRect(x: 0, y: window.frame.height / 3, width: window.frame.width, height: window.frame.height)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView.frame = CGRect(x: 0, y: window.frame.height, width: window.frame.width, height: window.frame.height)
        }) { (_) in
            transitionContext.containerView.backgroundColor = containerViewColor
            fromSnapShotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
