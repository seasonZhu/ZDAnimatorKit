//
//  AnimationMaskEffect.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class AnimationMaskEffect: AnimationBasicEffect {
    private var forwardToView: UIView!
    
    private weak var transitionContext: UIViewControllerContextTransitioning?
}

extension AnimationMaskEffect {
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        super.animateTransition(using: transitionContext)
    }
}

extension AnimationMaskEffect {
    override func transitionAnimationWithForward(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        transitionContext.containerView.backgroundColor = toView.backgroundColor
        let fromTargetView = fromVC.animationTransitionTargetView()
        
        if fromTargetView == nil  {
            transitionContext.containerView.addSubview(fromView)
            transitionContext.containerView.addSubview(toView)
            transitionContext.completeTransition(true)
            return
        }
        
        transitionContext.containerView.addSubview(fromView)
        transitionContext.containerView.addSubview(toView)
        
        let shapeLayer = CAShapeLayer()
        if let fromTargetImageView = fromTargetView as? UIImageView {
            shapeLayer.contents = fromTargetImageView.image?.cgImage
        }else {
            print("请在AnimationTransitionTargetView方法中,返回UIImageView类型的视图")
        }
        
        shapeLayer.bounds = fromTargetView!.bounds
        shapeLayer.position = fromTargetView!.center
        toView.layer.mask = shapeLayer
        forwardToView = toView
        
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "bounds")
        keyFrameAnimation.duration = kAnimationTransitionDuration
        let startValue = NSValue.init(cgRect: CGRect(x: 0, y: 0, width: fromTargetView!.frame.width, height: fromTargetView!.frame.height))
        let finialValue = NSValue.init(cgRect: CGRect(x: 0, y: 0, width: 2000, height: 2000))
        keyFrameAnimation.values = [startValue, finialValue]
        keyFrameAnimation.keyTimes = [0, 1]
        keyFrameAnimation.fillMode = kCAFillModeForwards
        keyFrameAnimation.isRemovedOnCompletion = false
        keyFrameAnimation.delegate = self
        shapeLayer.add(keyFrameAnimation, forKey: "keyFrameAnimation_forward")
    }
    
    override func transitionAnimationWithBack(using transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        transitionContext.containerView.backgroundColor = UIColor.white
        let toTargetView = toVC.animationTransitionTargetView()
        
        if toTargetView == nil  {
            transitionContext.containerView.addSubview(fromView)
            transitionContext.containerView.addSubview(toView)
            transitionContext.completeTransition(true)
            return
        }
        
        transitionContext.containerView.addSubview(toView)
        transitionContext.containerView.addSubview(fromView)
        
        let shapeLayer = CAShapeLayer()
        if let toTargetImageView = toTargetView as? UIImageView {
            shapeLayer.contents = toTargetImageView.image?.cgImage
        }else {
            print("请在AnimationTransitionTargetView方法中,返回UIImageView类型的视图")
        }
        
        shapeLayer.bounds = toTargetView!.bounds
        shapeLayer.position = toTargetView!.center
        fromView.layer.mask = shapeLayer
        forwardToView = fromView
        
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "bounds")
        keyFrameAnimation.duration = kAnimationTransitionDuration
        let startValue = NSValue.init(cgRect: CGRect(x: 0, y: 0, width: 2000, height: 2000))
        let finialValue = NSValue.init(cgRect: CGRect(x: 0, y: 0, width: toTargetView!.frame.width, height: toTargetView!.frame.height))
        keyFrameAnimation.values = [startValue, finialValue]
        keyFrameAnimation.keyTimes = [0, 1]
        keyFrameAnimation.fillMode = kCAFillModeForwards
        keyFrameAnimation.isRemovedOnCompletion = false
        keyFrameAnimation.delegate = self
        shapeLayer.add(keyFrameAnimation, forKey: "keyFrameAnimation_back")
    }
}

extension AnimationMaskEffect: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.transitionContext?.completeTransition(true)
        self.forwardToView.layer.mask = nil
    }
}
