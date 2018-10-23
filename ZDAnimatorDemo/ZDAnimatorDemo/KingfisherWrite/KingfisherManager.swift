//
//  KingfisherManager.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/19.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

typealias DownloadProgressBlock = ((_ receivedSize: Int64, _ totalSize: Int64) -> Void)
typealias CompletionHandler = ((_ image: Image?, _ error: NSError?, _ cacheType: CacheType, _ imageURL: URL?) -> Void)


final class RetrieveImageTask {
    
    static let empty = RetrieveImageTask()
    
    var cancelledBeforeDownloadStarting: Bool = false
    
    var downloadTask: RetrieveImageDownloadTask?
    
    func cancel() {
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        } else {
            cancelledBeforeDownloadStarting = true
        }
    }
}

/// Error domain of Kingfisher
public let KingfisherErrorDomain = "com.onevcat.Kingfisher.Error"


class KingfisherManager {
    static let shared = KingfisherManager()
    
    var cache: ImageCache
    
    var downloader: ImageDownloader
    
    var defaultOptions = KingfisherEmptyOptionsInfo
    
    var currentDefaultOptions: KingfisherOptionsInfo {
        return [.downloader(downloader), .targetCache(cache)] + defaultOptions
    }
    
    convenience init() {
        self.init(downloader: .default, cache: .default)
    }
    
    init(downloader: ImageDownloader, cache: ImageCache) {
        self.downloader = downloader
        self.cache = cache
    }
    
    /// 还原图片
    ///
    /// - Parameters:
    ///   - resource: 资源网址
    ///   - options: 选项
    ///   - progressBlock: 进度回调
    ///   - completionHandler: 完成回调
    /// - Returns: 图片任务
    @discardableResult
    func retrieveImage(with resource: Resource,
                       options: KingfisherOptionsInfo?,
                       progressBlock: DownloadProgressBlock?,
                       completionHandler: CompletionHandler?) -> RetrieveImageTask {
        let task = RetrieveImageTask()
        
        let options = currentDefaultOptions + (options ?? KingfisherEmptyOptionsInfo)
        
        if options.forceRefresh {
            _ = downloadAndCacheImage(with: resource.downloadURL, forKey: resource.cacheKey, retrieveImageTask: task, progressBlock: progressBlock, completionHandler: completionHandler, options: options)
        } else {
            tryToRetrieveImageFromCache(forKey: resource.cacheKey, with: resource.downloadURL, retrieveImageTask: task, progressBlock: progressBlock, completionHandler: completionHandler, options: options)
        }
        
        return task
    }
    
    /// 下载并缓存图片
    ///
    /// - Parameters:
    ///   - url: url
    ///   - key: key
    ///   - retrieveImageTask: 图片任务
    ///   - progressBlock: 进度回调
    ///   - completionHandler: 完成回调
    ///   - options: 选项
    /// - Returns: 还原图片的下载任务
    @discardableResult
    func downloadAndCacheImage(with url: URL, forKey key: String, retrieveImageTask: RetrieveImageTask, progressBlock: DownloadProgressBlock?, completionHandler: CompletionHandler?, options: KingfisherOptionsInfo) -> RetrieveImageDownloadTask? {
        let downloader = options.downloader
        return downloader.downloadImage(with: url, retrieveImageTask: retrieveImageTask, options: options, progressBlock: progressBlock, completionHandler: { (image, error, url, originalData) in
            let targetCache = options.targetCache
            
            //  错误处理
            if let error = error, error.code == KingfisherError.notModified.rawValue {
                targetCache.retrieveImage(forKey: key, options: options, completionHandler: { (cacheImage, cacheType) in
                    completionHandler?(cacheImage, nil, cacheType, url)
                })
            }
           
            //  成功 图片缓存
            if let image = image, let originalData = originalData {
                
                //  缓存
                targetCache.store(image, original: originalData, forKey: key, processorIdentifier: options.processor.identifier, cacheSerializer: options.cacheSerializer, toDisk: !options.cacheMemoryOnly, completionHandler: nil)
                
                //  判断是否是保存原图
                if options.cacheOriginalImage && options.processor != DefaultImageProcessor.default {
                    let originalCache = options.originalCache
                    let defaultProcessor = DefaultImageProcessor.default
                    
                    if let originalImage = defaultProcessor.process(item: .data(originalData), options: options) {
                        originalCache.store(originalImage, original: originalData, forKey: key, processorIdentifier: defaultProcessor.identifier, cacheSerializer: options.cacheSerializer, toDisk: !options.cacheMemoryOnly, completionHandler: nil)
                    }
                }
                
            }
            
            completionHandler?(image, error, .none, url)
        })
    }
    
    /// 尝试从缓存中获取图片
    ///
    /// - Parameters:
    ///   - key: key
    ///   - url: url
    ///   - retrieveImageTask: 图片任务
    ///   - progressBlock: 进度回调
    ///   - completionHandler: 完成回调
    ///   - options: 选项
    func tryToRetrieveImageFromCache(forKey key: String, with url: URL, retrieveImageTask: RetrieveImageTask, progressBlock: DownloadProgressBlock?, completionHandler: CompletionHandler?, options: KingfisherOptionsInfo) {
        
        //  初始化一个回调
        let diskTaskCompletionHandler: CompletionHandler = { (image, error, cacheType, imageURL) -> Void in
            completionHandler?(image, error, cacheType, imageURL)
        }
        
        //  没有缓存的处理
        func handleNoCache() {
            if options.onlyFromCache {
                let error = NSError(domain: KingfisherErrorDomain, code: KingfisherError.notCached.rawValue, userInfo: nil)
                diskTaskCompletionHandler(nil, error, .none, url)
                return
            }
            
            self.downloadAndCacheImage(with: url, forKey: key, retrieveImageTask: retrieveImageTask, progressBlock: progressBlock, completionHandler: diskTaskCompletionHandler, options: options)
        }
        
        let targetCache = options.targetCache
        targetCache.retrieveImage(forKey: key, options: options) { (image, cacheType) in
            if image != nil {
                diskTaskCompletionHandler(image, nil, cacheType, url)
                return
            }
        
            let proessor = options.processor
            guard proessor != DefaultImageProcessor.default else {
                handleNoCache()
                return
            }
            
            let originalCache = options.originalCache
            let optionsWithOutProcessor = options.removeAllMatchesIgnoringAssociatedValue(.processor(proessor))
            
            originalCache.retrieveImage(forKey: key, options: optionsWithOutProcessor) { (image, cacheType) in
                guard let image = image else {
                    handleNoCache()
                    return
                }
                
                guard let processedImage = proessor.process(item: .image(image), options: options) else {
                    diskTaskCompletionHandler(nil, nil, .none, url)
                    return
                }
                
                targetCache.store(processedImage, original: nil, forKey: key, processorIdentifier: options.processor.identifier, cacheSerializer: options.cacheSerializer, toDisk: !options.cacheMemoryOnly, completionHandler: nil)
                diskTaskCompletionHandler(processedImage, nil, .none, url)
            }
        }
    }
}
