//
//  AnimationTransitionConfig.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/13.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

/// 转场动画的时间
let kAnimationTransitionDuration: TimeInterval = 0.5

/// 屏幕边缘侧滑手势的移动比例,超出则触发转场
let kScreenEdgePanMoveScale: CGFloat = 0.4

/// 屏幕边缘侧滑手势的移动速度,超过则触发转场
let kScreenEdgePanMoveVelocity: CGFloat = 1000.0

/// 页面整体滑动手势的移动比例,超过则触发转场
let kPanGestureMoveScale: CGFloat = 0.4

/// 页面整体滑动手势的移动速度,超过则触发转场
let kPanGestureMoveVelocity: CGFloat = 1000.0


/// 动画效果枚举
///
/// - none: 不自定义动画,使用系统的              -不需要实现AnimationTransitionTargetView
/// - smooth: 平滑的转场,支持Push和Present        -不需要实现AnimationTransitionTargetView
/// - mask: Mask转场,仅支持Push                -fromVC实现AnimationTransitionTargetView,且必须返回UIImageView
/// - magicMove: 神奇移动转场,仅支持Push              -fromVC和toVC都必须实现AnimationTransitionTargetView
/// - tikToComment: 抖音的评论,仅支持Present            -不需要实现AnimationTransitionTargetView
enum AnimationTransitionType {
    case none, smooth, mask, magicMove, tikToComment
}

extension AnimationTransitionType {
    
}

/// 手势枚举
///
/// - none: 不增加滑动手势
/// - left: 响应左滑手势
/// - right: 响应右滑手势
/// - up: 响应上滑手势
/// - down: 响应下滑手势
enum PanDirectionStyle {
    case none, left, right, up, down
}


/// 协议-返回目标图片 这样框架性更强
protocol IAnimationTransition {
    func animationTransitionTargetView() -> UIView?
}

/// 协议-push or pop / present or dismiss 的操作行为
protocol IAnimationAction: class {
    func transitionAnimationWithForward(using transitionContext: UIViewControllerContextTransitioning)
    
    func transitionAnimationWithBack(using transitionContext: UIViewControllerContextTransitioning)
}
