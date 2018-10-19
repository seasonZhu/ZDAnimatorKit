//
//  KingfisherOptionsInfo.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]
let KingfisherEmptyOptionsInfo = [KingfisherOptionsInfoItem]()

enum KingfisherOptionsInfoItem {
    case targetCache(ImageCache)
    
    case originalCache(ImageCache)
    
    case downloader(ImageDownloader)
    
    case transition(ImageTransition)
    
    case downloadPriority(Float)
    
    case forceRefresh
    
    case fromMemoryCacheOrRefresh
    
    case forceTransition
    
    case cacheMemoryOnly
    
    case onlyFromCache
    
    case backgroundDecode
    
    case callbackDispatchQueue(DispatchQueue?)
    
    case scaleFactor(CGFloat)
    
    case preloadAllAnimationData
    
    case requestModifier(ImageDownloadRequestModifier)
    
    case processor(ImageProcessor)
    
    case cacheSerializer(CacheSerializer)
    
    case imageModifier(ImageModifier)
    
    case keepCurrentImageWhileLoading
    
    case onlyLoadFirstFrame
    
    case cacheOriginalImage
}

precedencegroup ItemComparisonPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

infix operator <== : ItemComparisonPrecedence

///  只有左右类型相同才返回真
func <== (lhs: KingfisherOptionsInfoItem, rhs: KingfisherOptionsInfoItem) -> Bool {
    switch (lhs, rhs) {
    case (.targetCache(_), .targetCache(_)): return true
    case (.originalCache(_), .originalCache(_)): return true
    case (.downloader(_), .downloader(_)): return true
    case (.transition(_), .transition(_)): return true
    case (.downloadPriority(_), .downloadPriority(_)): return true
    case (.forceRefresh, .forceRefresh): return true
    case (.fromMemoryCacheOrRefresh, .fromMemoryCacheOrRefresh): return true
    case (.forceTransition, .forceTransition): return true
    case (.cacheMemoryOnly, .cacheMemoryOnly): return true
    case (.onlyFromCache, .onlyFromCache): return true
    case (.backgroundDecode, .backgroundDecode): return true
    case (.callbackDispatchQueue(_), .callbackDispatchQueue(_)): return true
    case (.scaleFactor(_), .scaleFactor(_)): return true
    case (.preloadAllAnimationData, .preloadAllAnimationData): return true
    case (.requestModifier(_), .requestModifier(_)): return true
    case (.processor(_), .processor(_)): return true
    case (.cacheSerializer(_), .cacheSerializer(_)): return true
    case (.imageModifier(_), .imageModifier(_)): return true
    case (.keepCurrentImageWhileLoading, .keepCurrentImageWhileLoading): return true
    case (.onlyLoadFirstFrame, .onlyLoadFirstFrame): return true
    case (.cacheOriginalImage, .cacheOriginalImage): return true
    default: return false
    }
}
// FIXME: -重点学习
extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    func lastMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
        //  这里应该是可选类型的map
        return reversed().first { $0 <== target }
    }
    
    //  筛选出与target不同的选项
    func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
        return filter { !($0 <== target) }
    }
}

extension Collection where Iterator.Element == KingfisherOptionsInfoItem {
    var targetCache: ImageCache {
        if let item = lastMatchIgnoringAssociatedValue(.targetCache(.default)),
            case .targetCache(let cache) = item {
            return cache
        }
        
        return ImageCache.default
    }
    
    var originalCache: ImageCache {
        if let item = lastMatchIgnoringAssociatedValue(.originalCache(.default)),
            case .originalCache(let cache) = item
        {
            return cache
        }
        return targetCache
    }
    
    var downloader: ImageDownloader {
        if let item = lastMatchIgnoringAssociatedValue(.downloader(.default)),
            case .downloader(let downloader) = item
        {
            return downloader
        }
        return ImageDownloader.default
    }
    
    var transition: ImageTransition {
        if let item = lastMatchIgnoringAssociatedValue(.transition(.none)),
            case .transition(let transition) = item
        {
            return transition
        }
        return ImageTransition.none
    }
    
    var downloadPriority: Float {
        if let item = lastMatchIgnoringAssociatedValue(.downloadPriority(0)),
            case .downloadPriority(let priority) = item
        {
            return priority
        }
        return URLSessionTask.defaultPriority
    }
    
    var forceRefresh: Bool {
        return contains{ $0 <== .forceRefresh }
    }
    
    var fromMemoryCacheOrRefresh: Bool {
        return contains{ $0 <== .fromMemoryCacheOrRefresh }
    }
    
    var forceTransition: Bool {
        return contains{ $0 <== .forceTransition }
    }
    
    var cacheMemoryOnly: Bool {
        return contains{ $0 <== .cacheMemoryOnly }
    }
    
    var onlyFromCache: Bool {
        return contains{ $0 <== .onlyFromCache }
    }
    
    var backgroundDecode: Bool {
        return contains{ $0 <== .backgroundDecode }
    }
    
    var preloadAllAnimationData: Bool {
        return contains { $0 <== .preloadAllAnimationData }
    }
    
    var callbackDispatchQueue: DispatchQueue {
        if let item = lastMatchIgnoringAssociatedValue(.callbackDispatchQueue(nil)),
            case .callbackDispatchQueue(let queue) = item
        {
            return queue ?? DispatchQueue.main
        }
        return DispatchQueue.main
    }
    
    var scaleFactor: CGFloat {
        if let item = lastMatchIgnoringAssociatedValue(.scaleFactor(0)),
            case .scaleFactor(let scale) = item
        {
            return scale
        }
        return 1.0
    }
    
    var modifier: ImageDownloadRequestModifier {
        if let item = lastMatchIgnoringAssociatedValue(.requestModifier(NoModifier.default)),
            case .requestModifier(let modifier) = item
        {
            return modifier
        }
        return NoModifier.default
    }
    
    //TODO: -processor
    
    var imageModifier: ImageModifier {
        if let item = lastMatchIgnoringAssociatedValue(.imageModifier(DefaultImageModifier.default)),
            case .imageModifier(let imageModifier) = item
        {
            return imageModifier
        }
        return DefaultImageModifier.default
    }
    
    var cacheSerializer: CacheSerializer {
        if let item = lastMatchIgnoringAssociatedValue(.cacheSerializer(DefaultCacheSerializer.default)),
            case .cacheSerializer(let cacheSerializer) = item
        {
            return cacheSerializer
        }
        return DefaultCacheSerializer.default
    }
    
    var keepCurrentImageWhileLoading: Bool {
        return contains { $0 <== .keepCurrentImageWhileLoading }
    }
    
    var onlyLoadFirstFrame: Bool {
        return contains { $0 <== .onlyLoadFirstFrame }
    }
    
    var cacheOriginalImage: Bool {
        return contains { $0 <== .cacheOriginalImage }
    }
}

