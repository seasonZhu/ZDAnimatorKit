//
//  UINavigationController+AnimationTransition.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

extension UINavigationController {
    func pushVC(_ viewController: UIViewController, type: AnimationTransitionType) {
        switch type {
        case .none:
            pushVCWithNone(viewController)
        case .smooth:
            pushVCWithSmooth(viewController)
        case .magicMove:
            pushVCWithMagicMove(viewController)
        case .mask:
            pushVCWithMask(viewController)
        default:
            pushVCWithNone(viewController)
        }
    }
}

extension UINavigationController {
    private func pushVCWithNone(_ viewController: UIViewController) {
        self.delegate = nil
        viewController.animationTransition = nil
        pushViewController(viewController, animated: true)
    }
    
    private func pushVCWithSmooth(_ viewController: UIViewController) {
        let animationTransition = AnimationInteractiveTransition()
        animationTransition.type = .smooth
        animationTransition.targetView = viewController.view         //增加手势
        animationTransition.navigationController = self               //手势控制返回
        animationTransition.isOpenPanGesture = false                   //开启滑动手势
        animationTransition.directionStyle = .none     //设置侧滑方向
        animationTransition.isOpenScreenEdgePanGesture = true;       //开启侧滑返回,注意:手势重叠问题
        
        self.delegate = animationTransition
        self.animationTransition = animationTransition
        viewController.animationTransition = animationTransition
        
        pushViewController(viewController, animated: true)
    }
    
    private func pushVCWithMagicMove(_ viewController: UIViewController) {
        let animationTransition = AnimationInteractiveTransition()
        animationTransition.type = .magicMove
        animationTransition.targetView = viewController.view         //增加手势
        animationTransition.navigationController = self               //手势控制返回
        animationTransition.isOpenPanGesture = true                   //开启滑动手势
        animationTransition.directionStyle = .up     //设置侧滑方向
        animationTransition.isOpenScreenEdgePanGesture = true;       //开启侧滑返回,注意:手势重叠问题
        
        self.delegate = animationTransition
        self.animationTransition = animationTransition
        viewController.animationTransition = animationTransition
        
        pushViewController(viewController, animated: true)
    }
    
    private func pushVCWithMask(_ viewController: UIViewController) {
        let animationTransition = AnimationInteractiveTransition()
        animationTransition.type = .mask
        animationTransition.targetView = viewController.view         //增加手势
        animationTransition.navigationController = self               //手势控制返回
        animationTransition.isOpenPanGesture = false                   //开启滑动手势
        animationTransition.directionStyle = .none     //设置侧滑方向
        animationTransition.isOpenScreenEdgePanGesture = true;       //开启侧滑返回,注意:手势重叠问题
        
        self.delegate = animationTransition
        self.animationTransition = animationTransition
        viewController.animationTransition = animationTransition
        
        pushViewController(viewController, animated: true)
    }
}
