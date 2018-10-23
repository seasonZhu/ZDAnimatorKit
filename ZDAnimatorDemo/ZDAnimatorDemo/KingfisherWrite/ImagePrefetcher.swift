//
//  ImagePrefetcher.swift
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

typealias PrefetcherProgressBlock = ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> Void)

typealias PrefetcherCompletionHandler = ((_ skippedResources: [Resource], _ failedResources: [Resource], _ completedResources: [Resource]) -> Void)

class ImagePrefether {
    var maxConcurrentDownloads = 5
    
    private var prefetchQueue: DispatchQueue
    
    private let prefetchResources: [Resource]
    private let optionsInfo: KingfisherOptionsInfo
    private var progressBlock: PrefetcherProgressBlock?
    private var completionHandler: PrefetcherCompletionHandler?
    
    private var tasks = [URL: RetrieveImageDownloadTask]()
    
    private var pendingResources: ArraySlice<Resource>
    private var skippedResources = [Resource]()
    private var completedResources = [Resource]()
    private var failedResources = [Resource]()
    
    private var stopped = false
    
    private let manager: KingfisherManager
    
    private var finished: Bool {
        return failedResources.count + skippedResources.count + completedResources.count == prefetchResources.count && self.tasks.isEmpty
    }
    
    convenience init(urls: [URL],
                     options: KingfisherOptionsInfo? = nil,
                     progressBlock: PrefetcherProgressBlock? = nil,
                     completionHandler: PrefetcherCompletionHandler? = nil) {
        let resources: [Resource] = urls.map { (url) -> Resource in
            return url
        }
        
        //let resources: [Resource] = urls.map { $0 }
        
        self.init(resources: resources, options: options, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    init(resources: [Resource],
         options: KingfisherOptionsInfo? = nil,
         progressBlock: PrefetcherProgressBlock? = nil,
         completionHandler: PrefetcherCompletionHandler? = nil) {
        
        prefetchResources = resources
        pendingResources = ArraySlice(resources)
        
        let prefetchQueueName = "com.onevcat.Kingfisher.PrefetchQueue"
        prefetchQueue = DispatchQueue(label: prefetchQueueName)
        
        var optionsInfoWithoutQueue = options?.removeAllMatchesIgnoringAssociatedValue(.callbackDispatchQueue(nil)) ?? KingfisherEmptyOptionsInfo
        optionsInfoWithoutQueue.append(.callbackDispatchQueue(prefetchQueue))
        
        self.optionsInfo = optionsInfoWithoutQueue
        let cache = self.optionsInfo.targetCache
        let downloader = self.optionsInfo.downloader
        manager = KingfisherManager(downloader: downloader, cache: cache)
        
        self.progressBlock = progressBlock
        self.completionHandler = completionHandler
        
    }
    
    func start() {
        prefetchQueue.async {
            guard !self.stopped else {
                assertionFailure("You can not restart the same prefetcher. Try to create a new prefetcher.")
                self.handleComplete()
                return
            }
            
            guard self.maxConcurrentDownloads > 0 else {
                assertionFailure("There should be concurrent downloads value should be at least 1.")
                self.handleComplete()
                return
            }
            
            guard self.prefetchResources.count > 0 else {
                self.handleComplete()
                return
            }
            
            let initialConcurentDownloads = min(self.prefetchResources.count, self.maxConcurrentDownloads)
            
            for _ in 0 ..< initialConcurentDownloads {
                if let resource = self.pendingResources.popFirst() {
                    self.startPrefetching(resource)
                }
            }
        }
    }
    
    func stop() {
        prefetchQueue.async {
            if self.finished { return }
            self.stopped = true
            self.tasks.values.forEach({ (task) in
                task.cancel()
            })
            //self.tasks.values.forEach { $0.cancel() }
        }
    }
    
    func downloadAndCache(_ resource: Resource) {
        let downloadTaskCompletionHandler: CompletionHandler = { (image, error, _, _) -> Void in
            self.tasks.removeValue(forKey: resource.downloadURL)
            if let _ = error {
                self.failedResources.append(resource)
            }else {
                self.completedResources.append(resource)
            }
            
            self.reportProgress()
            if self.stopped {
                if self.tasks.isEmpty {
                    self.failedResources.append(contentsOf: self.prefetchResources)
                    self.handleComplete()
                }
            } else {
                self.reportCompletionOrStartNext()
            }
        }
        
        let downloadTask = manager.downloadAndCacheImage(with: resource.downloadURL, forKey: resource.cacheKey, retrieveImageTask: RetrieveImageTask(), progressBlock: nil, completionHandler: downloadTaskCompletionHandler, options: optionsInfo)
        
        if let downloadTask = downloadTask {
            tasks[resource.downloadURL] = downloadTask
        }
    }
    
    func append(cached resource: Resource) {
        skippedResources.append(resource)
        
        reportProgress()
        reportCompletionOrStartNext()
    }
    
    func startPrefetching(_ resource: Resource) {
        if optionsInfo.forceRefresh {
            downloadAndCache(resource)
        }else {
            let alreadyInCache = manager.cache.imageCachedType(forKey: resource.cacheKey, processorIdentifier: optionsInfo.processor.identifier).cached
            
            if alreadyInCache {
                append(cached: resource)
            }else {
                downloadAndCache(resource)
            }
        }
    }
    
    func reportProgress() {
        progressBlock?(skippedResources, failedResources, completedResources)
    }
    
    func reportCompletionOrStartNext() {
        prefetchQueue.async {
            if let resource = self.pendingResources.popLast() {
                self.startPrefetching(resource)
            }else {
                guard self.tasks.isEmpty else { return }
                self.handleComplete()
            }
        }
    }

    func handleComplete() {
        DispatchQueue.main.safeAsync {
            self.completionHandler?(self.skippedResources, self.failedResources, self.completedResources)
            self.completionHandler = nil
            self.progressBlock = nil
        }
    }
}
