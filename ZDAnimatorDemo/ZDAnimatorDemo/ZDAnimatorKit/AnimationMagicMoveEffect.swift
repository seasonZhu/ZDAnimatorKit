//
//  AnimationMagicMoveEffect.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class AnimationMagicMoveEffect: AnimationBasicEffect {
    ///  可重写UIViewControllerAnimatedTransitioning
}

extension AnimationMagicMoveEffect {
    override func transitionAnimationWithForward(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerViewColor = transitionContext.containerView.backgroundColor
        transitionContext.containerView.backgroundColor = UIColor.white
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        let fromTargetView = fromVC.animationTransitionTargetView()
        let toTargetView = toVC.animationTransitionTargetView()
        
        if fromTargetView == nil || toTargetView == nil {
            transitionContext.containerView.addSubview(fromView)
            transitionContext.containerView.addSubview(toView)
            transitionContext.completeTransition(true)
            return
        }
        
        transitionContext.containerView.addSubview(toView)
        toView.alpha = 0.2
        
        guard let fromSnapShotView = fromTargetView!.snapshotView(afterScreenUpdates: false) else {
            return
        }
        transitionContext.containerView.addSubview(fromSnapShotView)
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        guard let fromTargetPoint = fromTargetView!.superview?.convert(fromTargetView!.frame.origin, to: window) else { return }
        guard let toTargetPoint = toTargetView!.superview?.convert(toTargetView!.frame.origin, to: window) else { return }
        
        fromSnapShotView.frame = CGRect(x: fromTargetPoint.x, y: fromTargetPoint.y, width: fromTargetView!.frame.width, height: fromTargetView!.frame.height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromSnapShotView.frame = CGRect(x: toTargetPoint.x, y: toTargetPoint.y, width: toTargetView!.frame.width, height: toTargetView!.frame.height)
            toView.alpha = 1.0
        }) { (_) in
            toTargetView?.isHidden = false
            transitionContext.containerView.backgroundColor = containerViewColor
            fromSnapShotView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
    }
    
    override func transitionAnimationWithBack(using transitionContext: UIViewControllerContextTransitioning) {
        transitionAnimationWithForward(using: transitionContext)
    }
}
