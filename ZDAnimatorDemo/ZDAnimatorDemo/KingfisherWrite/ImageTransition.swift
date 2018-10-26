//
//  ImageTransition.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/19.
//  Copyright © 2018 season. All rights reserved.
//

#if os(macOS)
// Not implemented for macOS and watchOS yet.

import AppKit

/// Image transition is not supported on macOS.
enum ImageTransition {
    case none
    var duration: TimeInterval {
        return 0
    }
}

#elseif os(watchOS)
import UIKit
/// Image transition is not supported on watchOS.
enum ImageTransition {
    case none
    var duration: TimeInterval {
        return 0
    }
}
#else
import UIKit

enum ImageTransition {
    case none
    
    // 这个地方这么写fade(_ time: TimeInterval) 这么写fade(time: TimeInterval)都是可以 只是多了一个一个参数细节表示说明参数 不用也是可以的
    case fade(_ time: TimeInterval)
    
    case flipFromLeft(TimeInterval)
    
    case flipFromRight(TimeInterval)
    
    case flipFromTop(TimeInterval)
    
    case flipFromBottom(TimeInterval)
    
    case custom(duration: TimeInterval,
                options: UIViewAnimationOptions,
                animations: ((UIImageView, UIImage) -> Void)?,
                completion: ((Bool) -> Void)?)
    
    
    /// 这个地方的本质其实还是只读计算属性,下面的也是这个意思
    var duration: TimeInterval {
        switch self {
        case .none:                          return 0
        case .fade(let duration):            return duration
            
        case .flipFromLeft(let duration):    return duration
        case .flipFromRight(let duration):   return duration
        case .flipFromTop(let duration):     return duration
        case .flipFromBottom(let duration):  return duration
            
        case .custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIViewAnimationOptions {
        switch self {
        case .none:                         return []
        case .fade(_):                      return .transitionCrossDissolve
            
        case .flipFromLeft(_):              return .transitionFlipFromLeft
        case .flipFromRight(_):             return .transitionFlipFromRight
        case .flipFromTop(_):               return .transitionFlipFromTop
        case .flipFromBottom(_):            return .transitionFlipFromBottom
            
        case .custom(_, let options, _, _): return options
        }
    }
    
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .custom(_, _, let animations, _): return animations
        default: return { $0.image = $1 }
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}
#endif
