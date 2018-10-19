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
/*
class ImagePrefether {
    var maxConcurrentDownloads = 5
    
    private var prefetchQueue: DispatchQueue
    
    private let prefetchResources: [Resource]
    private let optionsInfo: KingfisherOptionsInfo
    private var progressBlock: PrefetcherProgressBlock?
    private var completionHandler: PrefetcherCompletionHandler?
    
    private var tasks = [URL: RetrieveImageDownloadTask]()
    
    private var pendingResources: ArraySlice<Resource>
    private var skippedResources: [Resource]
    private var completedResources: [Resource]
    private var failedResources = [Resource]()
    
    private var stopped = false
    
    private let manager: KingfisherManager
    
    private var finished: Bool {
        return failedResources.count + skippedResources.count + completedResources.count == prefetchResources.count && self.tasks.isEmpty
    }
    
    init(resources: [Resource],
         options: KingfisherOptionsInfo? = nil,
         progressBlock: PrefetcherProgressBlock? = nil,
         completionHandler: PrefetcherCompletionHandler? = nil) {
        
        prefetchResources = resources
        pendingResources = ArraySlice(resources)
        
        let prefetchQueueName = "com.onevcat.Kingfisher.PrefetchQueue"
        prefetchQueue = DispatchQueue(label: prefetchQueueName)
        
        // TODO: 缺少KingfisherManager参数
        
    }
}
*/
