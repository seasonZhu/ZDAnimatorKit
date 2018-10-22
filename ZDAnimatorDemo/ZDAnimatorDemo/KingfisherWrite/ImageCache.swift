//
//  ImageCache.swift
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

extension Notification.Name {
    static let KingfisherDidCleanDiskCache = Notification.Name.init("com.onevcat.Kingfisher.KingfisherDidCleanDiskCache")
}

let KingfisherDiskCacheCleanedHashKey = "com.onevcat.Kingfisher.cleanedHash"

typealias RetrieveImageDiskTask = DispatchWorkItem

enum CacheType {
    case none, memory, disk
    
    var cached: Bool {
        switch self {
        case .memory, .disk:
            return true
        case .none:
            return false
        }
    }
}

class ImageCache {
    
    //  memory
    fileprivate let memeoryCache = NSCache<NSString, AnyObject>()
    
    var maxMemoryCost: UInt = 0 {
        didSet {
            self.memeoryCache.totalCostLimit = Int(maxMemoryCost)
        }
    }
    
    //  disk
    fileprivate let ioQueue: DispatchQueue
    fileprivate var fileManager: FileManager!
    
    let diskCachePath: String
    var pathExtension: String?
    
    var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7
    
    var maxDiskCacheSize: UInt = 0
    
    let processQueue: DispatchQueue
    
    static let `default` = ImageCache(name: "default")
    
    typealias DiskCachePathClosure = (String?, String) -> String
    
    class func defaultDiskCachePathClosure(path: String?, cacheName: String) -> String {
        let dstPath = path ?? NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        return (dstPath as NSString).appendingPathComponent(cacheName)
    }
    
    //MARK:- 初始化方法
    init(name: String, path: String? = nil, diskCachePathCloure: DiskCachePathClosure = ImageCache.defaultDiskCachePathClosure ) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the cache. A cache with empty name is not permitted.")
        }
        
        let cacheName = "com.onevcat.Kingfisher.ImageCache.\(name)"
        memeoryCache.name = cacheName
        
        diskCachePath = diskCachePathCloure(path, cacheName)
        
        let ioQueueName = "com.onevcat.Kingfisher.ImageCache.ioQueue.\(name)"
        ioQueue = DispatchQueue(label: ioQueueName)
        
        let processQueueName = "com.onevcat.Kingfisher.ImageCache.processQueue.\(name)"
        processQueue = DispatchQueue(label: processQueueName, attributes: .concurrent)
        
        ioQueue.sync {
            fileManager = FileManager()
        }
        
        #if !os(macOS) && !os(watchOS)
            NotificationCenter.default.addObserver(
            self, selector: #selector(clearMemoryCache), name: .UIApplicationDidReceiveMemoryWarning, object: nil)
            NotificationCenter.default.addObserver(
            self, selector: #selector(cleanExpiredDiskCache), name: .UIApplicationWillTerminate, object: nil)
            NotificationCenter.default.addObserver(
            self, selector: #selector(backgroundCleanExpiredDiskCache), name: .UIApplicationDidEnterBackground, object: nil)
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK:- 保存图片
    func store(_ image: Image,
               original: Data? = nil,
               forKey key: String,
               processorIdentifier identifier: String = "",
               cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
               toDisk: Bool = true,
               completionHandler: (() -> Void)? = nil) {
        let computedKey = key.computedKey(with: identifier)
        memeoryCache.setObject(image, forKey: computedKey as NSString)
        
        func callHandlerInMainQueue() {
            if let handle = completionHandler {
                DispatchQueue.main.async {
                    handle()
                }
            }
        }
        
        if toDisk {
            ioQueue.async {
                if let data = serializer.data(with: image, original: original) {
                    if !self.fileManager.fileExists(atPath: self.diskCachePath) {
                        do {
                            try self.fileManager.createDirectory(atPath: self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
                        }catch _ {
                            
                        }
                    }
                    
                    self.fileManager.createFile(atPath: self.cachePath(forKey: computedKey), contents: data, attributes: nil)
                }
                callHandlerInMainQueue()
            }
        }else {
            callHandlerInMainQueue()
        }
    }
    
    
    //MARK:- 移除图片
    func removeImage(forKey key: String,
                     processorIdentifier identifier: String = "",
                     fromMemory: Bool = true,
                     fromDisk: Bool = true,
                     completionHandler: (() -> Void)? = nil) {
        let computedKey = key.computedKey(with: identifier)
        
        if fromMemory {
            memeoryCache.removeObject(forKey: computedKey as NSString)
        }
        
        func callHandlerInMainQueue() {
            if let handler = completionHandler {
                DispatchQueue.main.async {
                    handler()
                }
            }
        }
        
        if fromDisk {
            ioQueue.async {
                do {
                    try self.fileManager.removeItem(atPath: self.cachePath(forKey: computedKey))
                }catch _ {
                    
                }
                callHandlerInMainQueue()
            }
        }else {
            callHandlerInMainQueue()
        }
    }
    
    @discardableResult
    open func retrieveImage(forKey key: String,
                            options: KingfisherOptionsInfo?,
                            completionHandler: ((Image?, CacheType) -> Void)?) -> RetrieveImageDiskTask?
    {
        guard let completionHandler = completionHandler else {
            return nil
        }
        
        var block: RetrieveImageDiskTask?
        let options = options ?? KingfisherEmptyOptionsInfo
        let imageModifier = options.imageModifier
        
        if let image = self.retrieveImageInMemoryCache(forKey: key, options: options) {
            options.callbackDispatchQueue.safeAsync {
                completionHandler(imageModifier.modify(image), .memory)
            }
        }else if options.fromMemoryCacheOrRefresh {
            options.callbackDispatchQueue.safeAsync {
                completionHandler(nil, .none)
            }
        }else {
            var sSelf: ImageCache! = self
            block = DispatchWorkItem(block: {
                if let image = sSelf.retrieveImageInDiskCache(forKey: key, options: options) {
                    if options.backgroundDecode {
                        let result = image.kf.decoded
                        
                        sSelf.store(result, forKey: key, processorIdentifier: options.processor.identifier, cacheSerializer: options.cacheSerializer, toDisk: false, completionHandler: nil)
                        
                        options.callbackDispatchQueue.safeAsync {
                            completionHandler(imageModifier.modify(result), .memory)
                            sSelf = nil
                        }
                    }else {
                        sSelf.store(image, forKey: key, processorIdentifier: options.processor.identifier, cacheSerializer: options.cacheSerializer, toDisk: false, completionHandler: nil)
                        
                        options.callbackDispatchQueue.safeAsync {
                            completionHandler(imageModifier.modify(image), .disk)
                            sSelf = nil
                        }

                    }
                }else {
                    options.callbackDispatchQueue.safeAsync {
                        completionHandler(nil, .none)
                        sSelf = nil
                    }
                }
            })
            
            sSelf.ioQueue.async(execute: block!)
        }
        
        return block
    }
    
    func retrieveImageInMemoryCache(forKey key: String, options: KingfisherOptionsInfo? = nil) -> Image? {
        
        let options = options ?? KingfisherEmptyOptionsInfo
        let computedKey = key.computedKey(with: options.processor.identifier)
    
        return memeoryCache.object(forKey: computedKey as NSString) as? Image
    }
    
    func retrieveImageInDiskCache(forKey key: String, options: KingfisherOptionsInfo? = nil) -> Image? {
        
        let options = options ?? KingfisherEmptyOptionsInfo
        let computedKey = key.computedKey(with: options.processor.identifier)
        
        return diskImage(forComputedKey: computedKey, serializer: options.cacheSerializer, options: options)
    }
    
    //MARK:- 清除内存中的缓存
    @objc func clearMemoryCache() {
        memeoryCache.removeAllObjects()
    }

    //MARK:- 清除沙盒中的缓存
    func clearDiskCache(completion handler: (()->())? = nil) {
        ioQueue.async {
            do {
                try self.fileManager.removeItem(atPath: self.diskCachePath)
                try self.fileManager.createDirectory(atPath: self.diskCachePath, withIntermediateDirectories: true, attributes: nil)
            } catch _ { }
            
            if let handler = handler {
                DispatchQueue.main.async {
                    handler()
                }
            }
        }
    }
    
    //MARK:- 清除过期的沙盒缓存
    @objc func cleanExpiredDiskCache() {
        cleanExpireDiskCache(completion: nil)
    }
    
    //MARK:- 带闭包的清除过期的沙盒缓存
    func cleanExpireDiskCache(completion handler: (()->())? = nil) {
        ioQueue.async {
            var (URLsToDelete, diskCacheSize, cachedFiles) = self.travelCachedFiles(onlyForCacheSize: false)
            
            /// 清理一定过期的文件
            for fileURL in URLsToDelete {
                do {
                    try self.fileManager.removeItem(at: fileURL)
                }catch _ {
                    
                }
            }
            
            /// 如果目前的缓存大于设定缓存 那么对现有没有过期的文件进行排序,并进行清理
            if self.maxDiskCacheSize > 0 && diskCacheSize > self.maxDiskCacheSize {
                let targetSize = self.maxDiskCacheSize / 2
                
                let sortedFiles = cachedFiles.keysSortedByValue({ (resourceValue1, resourceValue2) -> Bool in
                    
                    if let date1 = resourceValue1.contentAccessDate, let date2 = resourceValue2.contentAccessDate {
                        return date1.compare(date2) == .orderedAscending
                    }
                    
                    return true
                })
                
                for fileURL in sortedFiles {
                    do {
                        try self.fileManager.removeItem(at: fileURL)
                    }catch _ {
                        
                    }
                    
                    URLsToDelete.append(fileURL)
                    
                    if let fileSize = cachedFiles[fileURL]?.totalFileAllocatedSize {
                        diskCacheSize -= UInt(fileSize)
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                }
            }
            
            /// 发通知 清理完成
            DispatchQueue.main.async {
                if URLsToDelete.count != 0 {
                    let cleanedHashes = URLsToDelete.map { $0.lastPathComponent }
                    NotificationCenter.default.post(name: .KingfisherDidCleanDiskCache, object: self, userInfo: [KingfisherDiskCacheCleanedHashKey: cleanedHashes])
                }
                
                handler?()
            }
        }
    }
    
    //MARK:- 遍历缓存文件
    private func travelCachedFiles(onlyForCacheSize: Bool) -> (urlsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: URLResourceValues]) {
        let diskCacheURL = URL(fileURLWithPath: diskCachePath)
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .contentAccessDateKey, .totalFileAllocatedSizeKey]
        let expiredDate: Date? = (maxCachePeriodInSecond < 0) ? nil : Date(timeIntervalSinceNow: -maxCachePeriodInSecond)
        
        var cachedFiles = [URL: URLResourceValues]()
        var urlsToDelete = [URL]()
        var diskCacheSize: UInt = 0
        
        for fileUrl in (try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)) ?? [] {
            do {
                let resourceValues = try fileUrl.resourceValues(forKeys: resourceKeys)
                
                if resourceValues.isDirectory == true {
                    continue
                }
                
                if !onlyForCacheSize, let expiredDate = expiredDate, let lastAccessDate = resourceValues.contentAccessDate, (lastAccessDate as NSDate).laterDate(expiredDate) == expiredDate {
                    urlsToDelete.append(fileUrl)
                    continue
                }
                
                if let fileSize = resourceValues.totalFileAllocatedSize {
                    diskCacheSize += UInt(fileSize)
                    if !onlyForCacheSize {
                        cachedFiles[fileUrl] = resourceValues
                    }
                }
                
            }catch _ {
                
            }
        }
        
        return (urlsToDelete, diskCacheSize, cachedFiles)
    }
    
    // FIXME: -重点学习
    //MARK:- 后台进行过期缓存的沙盒清理
    #if !os(macOS) && !os(watchOS)
    @objc func backgroundCleanExpiredDiskCache() {
        guard let shareApplication = Kingfisher<UIApplication>.shared else {
            return
        }
        
        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            shareApplication.endBackgroundTask(task)
            task = UIBackgroundTaskInvalid
        }
        
        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = shareApplication.beginBackgroundTask(expirationHandler: {
            endBackgroundTask(&backgroundTask!)
        })
        
        cleanExpireDiskCache {
            endBackgroundTask(&backgroundTask!)
        }
    }
    #endif
    
    //MARK:- 获取缓存状态
    func imageCachedType(forKey key: String, processorIdentifier identifier: String = "") -> CacheType {
        let computedKey = key.computedKey(with: identifier)
        
        if memeoryCache.object(forKey: computedKey as NSString) != nil {
            return .memory
        }
        
        let filePath = cachePath(forComputedKey: computedKey)
        
        var diskCached = false
        
        //  串行队列 干完了个事才能继续往下走
        ioQueue.sync {
            diskCached = fileManager.fileExists(atPath: filePath)
        }
        
        if diskCached {
            return .disk
        }
        
        return .none
    }
    
    //MARK:- key取hash值
    func hash(forKey key: String, processorIdentifier identifier: String = "") -> String {
        let computedKey = key.computedKey(with: identifier)
        return cacheFileName(forComputedKey: computedKey)
    }
    
    //MARK:- 获取沙盒的缓存大小 callback回调是因为计算文件大小是异步进行的
    func calculateDiskCacheSize(completion handler: @escaping ((_ size: UInt) -> Void)) {
        ioQueue.async {
            let (_, diskCacheSize, _) = self.travelCachedFiles(onlyForCacheSize: true)
            DispatchQueue.main.async {
                handler(diskCacheSize)
            }
        }
    }
    
    //MARK:- 获取缓存路径
    func cachePath(forKey key: String, processorIdentifier identifier: String = "") -> String {
        let computedKey = key.computedKey(with: identifier)
        return cachePath(forComputedKey: computedKey)
    }
    
    func cachePath(forComputedKey key: String) -> String {
        let fileName = cacheFileName(forComputedKey: key)
        return (diskCachePath as NSString).appendingPathComponent(fileName)
    }
}

// MARK: - ImageCache 内部方法
extension ImageCache {
    
    func diskImage(forComputedKey key: String, serializer: CacheSerializer, options: KingfisherOptionsInfo) -> Image? {
        if let data = diskImageData(forComputedKey: key) {
            return serializer.image(with: data, options: options)
        } else {
            return nil
        }
    }
    
    func diskImageData(forComputedKey key: String) -> Data? {
        let filePath = cachePath(forComputedKey: key)
        return (try? Data(contentsOf: URL(fileURLWithPath: filePath)))
    }
    
    func cacheFileName(forComputedKey key: String) -> String {
        if let ext = pathExtension {
            return (key.kf.md5 as NSString).appendingPathExtension(ext)!
        }
        return key.kf.md5
    }
}

// MARK: - Deprecated

extension Kingfisher where Base: Image {
    var imageCost: Int {
        return images == nil ? Int(size.height * size.width * scale * scale) : Int(size.height * size.width * scale * scale) * images!.count
    }
}

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted{ isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

#if !os(macOS) && !os(watchOS)
extension UIApplication: KingfisherCompatible {}
extension Kingfisher where Base: UIApplication {
    static var shared: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        guard Base.responds(to: selector) else { return nil }
        return Base.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
}
#endif


extension String {
    func computedKey(with identifier: String) -> String {
        if identifier.isEmpty {
            return self
        }else {
            return appending("@\(identifier)")
        }
    }
}
