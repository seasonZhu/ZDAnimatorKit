//
//  AnimationInteractiveTransition.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class AnimationInteractiveTransition: UIPercentDrivenInteractiveTransition {
    
    //MARK:- 对外属性
    
    /// 使用Push转场时使用,其它情况应为nil
    var navigationController: UINavigationController?
    
    /// 使用Present转场时使用,其它情况应为nil
    var currentViewController: UIViewController?
    
    /// 增加手势的目标视图
    var targetView: UIView?
    
    /// 是否开启侧滑返回手势
    var isOpenScreenEdgePanGesture: Bool = false {
        willSet {
            if newValue {
                let edgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePanGesture(_ :)))
                edgePanGesture.edges = .left
                edgePanGesture.delegate = self
                targetView?.addGestureRecognizer(edgePanGesture)
            }
        }
    }
    
    /// 是否开启整体滑动手势,利用此参数,可以自定义滑动时机,例如:当contenOffset=0时,在开启滑动手势
    var isOpenPanGesture: Bool = false
    
    /// 是否开启整体滑动手势
    var directionStyle: PanDirectionStyle = .none {
        willSet {
            if newValue != .none {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
                targetView?.addGestureRecognizer(pan)
            }
        }
    }
    
    /// 动画类型
    var type: AnimationTransitionType = .none
    
    
    /// 代理
    private var animtedTransitioning: UIViewControllerAnimatedTransitioning?
    
    /// 是否是Pop或者Dismiss
    private var isBack: Bool = false
    
    /// 是否手势过渡
    private var isInteractive: Bool = false
}

extension AnimationInteractiveTransition {
    private func handleAnimatedTransitioning() {
        switch type {
        case .none:
            animtedTransitioning = nil
        case .mask:
            animtedTransitioning = AnimationMaskEffect(isBack: isBack)
        case .smooth:
            animtedTransitioning = AnimationSmoothEffect(isBack: isBack)
        case .magicMove:
            animtedTransitioning = AnimationMagicMoveEffect(isBack: isBack)
        case .tikToComment:
            animtedTransitioning = AnimationTikTokEffect(isBack: isBack)
        }
    }
    
    @objc private func handleEdgePanGesture(_ edgePanGesture: UIScreenEdgePanGestureRecognizer) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let rate = edgePanGesture.translation(in: window).x / UIScreen.main.bounds.width
        let velocity = edgePanGesture.velocity(in: window).x
        handleGesture(edgePanGesture, rate: rate, velocity: velocity)
    }
    
    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
        if !isInteractive {
            return
        }
        
        var currentDirction = PanDirectionStyle.none
    
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let translationX = panGesture.translation(in: window).x
        let translationY = panGesture.translation(in: window).y
        
        let moveRangeWidth = UIScreen.main.bounds.width
        var moveRangeHeight = UIScreen.main.bounds.height
        
        if type == .tikToComment {
            moveRangeHeight = UIScreen.main.bounds.height * 0.618
        }
        
        var rate = panGesture.translation(in: window).x / moveRangeWidth
        var velocity = panGesture.translation(in: window).y / moveRangeHeight
        
        if fabs(translationX) > fabs(translationY) {
            if translationX > 0 {
                //  右滑
                currentDirction = .right
            }else {
                //  左滑
                currentDirction = .left
            }
        }else {
            rate = fabs(panGesture.translation(in: window).y / moveRangeHeight)
            velocity = fabs(panGesture.velocity(in: window).y)
            
            if translationY > 0 {
                //  下滑
                currentDirction = .down
            }else if translationY < 0 {
                //  上滑
                currentDirction = .up
            }
        }
        
        if currentDirction == directionStyle {
            handleGesture(panGesture, rate: min(1.0, rate), velocity: velocity)
        }
        
    }
    
    private func handleGesture(_ gesture: UIGestureRecognizer, rate: CGFloat, velocity: CGFloat) {
        switch gesture.state {
        case .began:
            isInteractive = true
            if navigationController != nil {
                self.navigationController?.popViewController(animated: true)
            }else {
                self.currentViewController?.dismiss(animated: true, completion: nil)
            }
        case .changed:
            isInteractive = false
            update(rate)
        default:
            isInteractive = false
            if rate >= kScreenEdgePanMoveScale {
                finish()
            }else {
                if velocity > kScreenEdgePanMoveVelocity {
                    finish()
                }else {
                    cancel()
                }
            }
        }
    }
}

extension AnimationInteractiveTransition: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return isInteractive ? isBack ? self : nil : nil
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            isBack = false
        }else if operation == .pop {
            isBack = true
        }
        handleAnimatedTransitioning()
        return animtedTransitioning
    }
    
}

extension AnimationInteractiveTransition: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isBack = false
        handleAnimatedTransitioning()
        return animtedTransitioning
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isBack = true
        handleAnimatedTransitioning()
        return animtedTransitioning
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return isInteractive ? isBack ? self : nil : nil
    }
}

extension AnimationInteractiveTransition: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let point = touch.location(in: targetView) as? CGPoint else {
            return false
        }
        
        if point.x < 100 {
            return true
        }else {
            return false
        }
    }
}
