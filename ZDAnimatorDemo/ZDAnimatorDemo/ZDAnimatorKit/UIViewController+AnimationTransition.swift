//
//  UIViewController+AnimationTransition.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

private var InteractiveTransitionKey = "InteractiveTransitionKey"

extension UIViewController {
    
    /// AnimationInteractiveTransition
    var animationTransition: AnimationInteractiveTransition? {
        get {
            return (objc_getAssociatedObject(self, &InteractiveTransitionKey) as? AnimationInteractiveTransition)
        }
        set {
            objc_setAssociatedObject(self, &InteractiveTransitionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func presentVC(_ viewController: UIViewController, type: AnimationTransitionType) {
        switch type {
        case .none:
            presentVCWithNone(viewController)
        case .smooth:
            presentVCWithSmooth(viewController)
        case .magicMove:
            presentVCWithMagicMove(viewController)
        case .tikToComment:
            presentVCWithTikTokComment(viewController)
        default:
            presentVCWithNone(viewController)
        }
    }
}

extension UIViewController {
    private func presentVCWithNone(_ viewController: UIViewController) {
        viewController.transitioningDelegate = nil
        viewController.animationTransition = nil
        present(viewController, animated: true)
    }
    
    private func presentVCWithSmooth(_ viewController: UIViewController) {
        let animationTransition = AnimationInteractiveTransition()
        animationTransition.type = .smooth
        animationTransition.targetView = viewController.view         //增加手势
        animationTransition.navigationController = nil               //手势控制返回
        animationTransition.currentViewController = viewController;  //手势控制返回
        animationTransition.isOpenPanGesture = false                   //开启滑动手势
        animationTransition.directionStyle = .none     //设置侧滑方向
        animationTransition.isOpenScreenEdgePanGesture = true;       //开启侧滑返回,注意:手势重叠问题
        
        viewController.transitioningDelegate = animationTransition
        viewController.animationTransition = animationTransition
        
        self.animationTransition = animationTransition
        
        present(viewController, animated: true)
    }
    
    private func presentVCWithMagicMove(_ viewController: UIViewController) {
        let animationTransition = AnimationInteractiveTransition()
        animationTransition.type = .magicMove
        animationTransition.targetView = viewController.view         //增加手势
        animationTransition.navigationController = nil               //手势控制返回
        animationTransition.currentViewController = viewController;  //手势控制返回
        animationTransition.isOpenPanGesture = true                   //开启滑动手势
        animationTransition.directionStyle = .up     //设置侧滑方向
        animationTransition.isOpenScreenEdgePanGesture = true;       //开启侧滑返回,注意:手势重叠问题
        
        viewController.transitioningDelegate = animationTransition
        viewController.animationTransition = animationTransition
        
        self.animationTransition = animationTransition
        
        present(viewController, animated: true)
    }
    
    private func presentVCWithTikTokComment(_ viewController: UIViewController) {
        let animationTransition = AnimationInteractiveTransition()
        animationTransition.type = .tikToComment
        animationTransition.targetView = nil         //增加手势
        animationTransition.navigationController = nil               //手势控制返回
        animationTransition.currentViewController = viewController;  //手势控制返回
        animationTransition.isOpenPanGesture = true                   //开启滑动手势
        animationTransition.directionStyle = .down     //设置侧滑方向
        animationTransition.isOpenScreenEdgePanGesture = false;       //开启侧滑返回,注意:手势重叠问题
        
        viewController.transitioningDelegate = animationTransition
        viewController.animationTransition = animationTransition
        
        self.animationTransition = animationTransition
        
        present(viewController, animated: true)
    }
}

extension UIViewController: IAnimationTransition {
    @objc func animationTransitionTargetView() -> UIView? {
        return nil
    }
}
