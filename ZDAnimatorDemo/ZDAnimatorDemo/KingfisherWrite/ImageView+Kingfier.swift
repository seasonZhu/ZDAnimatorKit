//
//  ImageView+Kingfier.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/22.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Kingfisher where Base: ImageView {
    @discardableResult
    func setImage(with resource: Resource?,
                  placeholder: Placeholder? = nil,
                  options: KingfisherOptionsInfo? = nil,
                  progressBlock: DownloadProgressBlock? = nil,
                  completionHandler: CompletionHandler? = nil) -> RetrieveImageTask {
        guard let resource = resource else {
            self.placeholder = placeholder
            setWebURL(nil)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        var options = KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo)
        let noImageOrPlaceholderSet = base.image == nil && self.placeholder == nil
        
        if !options.keepCurrentImageWhileLoading || noImageOrPlaceholderSet {
            self.placeholder = placeholder
        }
        
        let maybeIndicator = indicator
        maybeIndicator?.startAnimatingView()
        
        setWebURL(resource.downloadURL)
        
        if base.shouldPreloadAllAnimation() {
            options.append(.preloadAllAnimationData)
        }
        
        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options, progressBlock: { (receivedSize, totalSize) in
            guard resource.downloadURL == self.webURL else {
                return
            }
            if let progressBlock = progressBlock {
                progressBlock(receivedSize, totalSize)
            }
        }) { [weak base] (image, error, cacheType, imageURL) in
            DispatchQueue.main.safeAsync {
                maybeIndicator?.stopAnimatingView()
                guard let strongBase = base, imageURL == self.webURL else {
                    completionHandler?(image, error, cacheType, imageURL)
                    return
                }
                
                self.setImageTask(nil)
                guard let image = image else {
                    completionHandler?(nil, error, cacheType, imageURL)
                    return
                }
                
                guard let transitionItem = options.lastMatchIgnoringAssociatedValue(.transition(.none)),
                    case .transition(let transition) = transitionItem,
                    (options.forceTransition || cacheType == .none) else {
                    self.placeholder = nil
                    strongBase.image = image
                    completionHandler?(image, error, cacheType, imageURL)
                    return
                }
                
                #if !os(macOS)
                UIView.transition(with: strongBase, duration: 0.0, options: [], animations: {
                    maybeIndicator?.stopAnimatingView()
                }, completion: { (_) in
                    self.placeholder = nil
                    UIView.transition(with: strongBase, duration: transition.duration, options: [transition.animationOptions, .allowUserInteraction], animations: {
                        transition.animations?(strongBase, image)
                    }, completion: { (finished) in
                        transition.completion?(finished)
                        completionHandler?(image, error, cacheType, imageURL)
                    })
                })
                #endif
            }
        }
        
        setImageTask(task)
        
        return task
    }
    
    func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var indicatorKey: Void?
private var indicatorTypeKey: Void?
private var placeholderKey: Void?
private var imageTaskKey: Void?

extension Kingfisher where Base: ImageView {
    
    //  这个其实是变相的将属性的set与get方法分开 而且让属性变成了只读属性
    var webURL: URL? {
        return objc_getAssociatedObject(base, &lastURLKey) as? URL
    }
    
    fileprivate func setWebURL(_ url: URL?) {
        objc_setAssociatedObject(base, &lastURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    var indicatorType:IndicatorType {
        get {
            let indicator = objc_getAssociatedObject(base, &indicatorTypeKey) as? IndicatorType
            return indicator ?? .none
        }set {
            switch newValue {
            case .none:
                indicator = nil
            case .activity:
                indicator = ActivityIndicator()
            case .image(let data):
                indicator = ImageIndicator(imageData: data)
            case .cunstom(indicator: let anIndicator):
                indicator = anIndicator
                break
            }
            objc_setAssociatedObject(base, &indicatorTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate(set) var indicator: Indicator? {
        get {
            guard let box = objc_getAssociatedObject(base, &indicatorKey) as? Box<Indicator> else {
                return nil
            }
            return box.value
        }
        
        set {
            //  去掉之前的
            if let previousIndicator = indicator {
                previousIndicator.view.removeFromSuperview()
            }
            
            //  添加现在的 if var 也是可以的 也可以守护有值 而且可以做改变
            if var newIndicator = newValue {
                if newIndicator.view.frame == .zero {
                    newIndicator.view.frame = base.frame
                }
                newIndicator.viewCenter = CGPoint(x: base.bounds.midX, y: base.bounds.midY)
                newIndicator.view.isHidden = true
                base.addSubview(newIndicator.view)
                //  其实这一行的Box.init我没有明白 另外 对于协议的map 我也需要好好学习一下
                objc_setAssociatedObject(base, &indicatorKey, newValue.map(Box.init), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate(set) var placeholder: Placeholder? {
        get {
            return objc_getAssociatedObject(base, &placeholderKey) as? Placeholder
        }
        
        set {
            if let previonsPlaceholder = placeholder {
                previonsPlaceholder.remove(frome: base)
            }
            
            if let newPlaceholder = newValue {
                newPlaceholder.add(to: base)
            }else {
                base.image = nil
            }
            objc_setAssociatedObject(base, &placeholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@objc extension ImageView {
    func shouldPreloadAllAnimation() -> Bool { return true }
}
