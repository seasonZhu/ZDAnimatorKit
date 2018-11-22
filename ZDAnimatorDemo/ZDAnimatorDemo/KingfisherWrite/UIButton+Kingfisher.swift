//
//  UIButton+Kingfisher.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/22.
//  Copyright © 2018 season. All rights reserved.
//

import UIKit

extension Kingfisher where Base: UIButton {
    @discardableResult
    func setImage(with resource: Resource?,
                         for state: UIControlState,
                         placeholder: UIImage? = nil,
                         options: KingfisherOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask {
        guard let resource = resource else {
            base.setImage(placeholder, for: state)
            setWebURL(nil, for: state)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo)
        if !options.keepCurrentImageWhileLoading {
            base.setImage(placeholder, for: state)
        }
        
        setWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options, progressBlock: { (receivedSize, totalSize) in
            guard resource.downloadURL == self.webURL(for: state) else {
                return
            }
            
            if let progressBlock = progressBlock {
                progressBlock(receivedSize, totalSize)
            }
        }) { [weak base] (image, error, cacheType, imageURL) in
            DispatchQueue.main.safeAsync {
                guard let strongBase = base, imageURL == self.webURL(for: state) else {
                    completionHandler?(image, error, cacheType, imageURL)
                    return
                }
                self.setImageTask(nil)
                if image != nil {
                    strongBase.setImage(image, for: state)
                }
                
                completionHandler?(image, error, cacheType, imageURL)
            }
        }
        setImageTask(task)
        return task
    }
    
    func cancelImageDownloadTask() {
        imageTask?.cancel()
    }
    
    @discardableResult
    func setBackgroundImage(with resource: Resource?,
                                   for state: UIControlState,
                                   placeholder: UIImage? = nil,
                                   options: KingfisherOptionsInfo? = nil,
                                   progressBlock: DownloadProgressBlock? = nil,
                                   completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            base.setBackgroundImage(placeholder, for: state)
            setBackgroundWebURL(nil, for: state)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = KingfisherManager.shared.defaultOptions + (options ?? KingfisherEmptyOptionsInfo)
        if !options.keepCurrentImageWhileLoading {
            base.setBackgroundImage(placeholder, for: state)
        }
        
        setBackgroundWebURL(resource.downloadURL, for: state)
        let task = KingfisherManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.backgroundWebURL(for: state) else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
        },
            completionHandler: { [weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.backgroundWebURL(for: state) else {
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }
                    self.setBackgroundImageTask(nil)
                    if image != nil {
                        strongBase.setBackgroundImage(image, for: state)
                    }
                    completionHandler?(image, error, cacheType, imageURL)
                }
        })
        
        setBackgroundImageTask(task)
        return task
    }
    
    func cancelBackgroundImageDownloadTask() {
        backgroundImageTask?.cancel()
    }
}


private var lastURLKey: Void?
private var imageTaskKey: Void?

extension Kingfisher where Base: UIButton {
    
    func webURL(for state: UIControlState) -> URL? {
        return webURLs[NSNumber(value: state.rawValue)] as? URL
    }
    
    fileprivate func setWebURL(_ url: URL?, for state: UIControlState) {
        webURLs[NSNumber(value: state.rawValue)] = url
    }
    
    /// 我没有明白的是这个地方为何要是使用NSMutableDictionary 使用Dictionary会有问题吗?
    fileprivate var webURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(base, &lastURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            setWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func setWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(base, &lastURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private var lastBackgroundURLKey: Void?
private var backgroundImageTaskKey: Void?


extension Kingfisher where Base: UIButton {
    func backgroundWebURL(for state: UIControlState) -> URL? {
        return backgroundWebURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func setBackgroundWebURL(_ url: URL?, for state: UIControlState) {
        backgroundWebURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var backgroundWebURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(base, &lastBackgroundURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            setBackgroundWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func setBackgroundWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(base, &lastBackgroundURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var backgroundImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &backgroundImageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setBackgroundImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &backgroundImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
