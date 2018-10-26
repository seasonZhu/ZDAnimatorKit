//
//  ImageDownloader.swift
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

/// 回调进度
typealias ImageDownloaderProgressBlock = DownloadProgressBlock

/// 回调下载完成
typealias ImageDownloaderCompletionHandler = ((_ image: Image?, _ error: NSError?, _ url: URL?, _ originalData: Data?) -> Void)

struct RetrieveImageDownloadTask {
    let internalTask: URLSessionDataTask
    
    fileprivate(set) weak var ownerDownloader: ImageDownloader?
    
    func cancel() {
        ownerDownloader?.cancel(self)
    }
    
    var url: URL? {
        return internalTask.originalRequest?.url
    }
    
    var priority: Float {
        get {
            return internalTask.priority
        }set {
            internalTask.priority = newValue
        }
    }

}

enum KingfisherError: Int {
    /// badData: The downloaded data is not an image or the data is corrupted.
    case badData = 10000
    
    /// notModified: The remote server responded a 304 code. No image data downloaded.
    case notModified = 10001
    
    /// The HTTP status code in response is not valid. If an invalid
    /// code error received, you could check the value under `KingfisherErrorStatusCodeKey`
    /// in `userInfo` to see the code.
    case invalidStatusCode = 10002
    
    /// notCached: The image requested is not in cache but .onlyFromCache is activated.
    case notCached = 10003
    
    /// The URL is invalid.
    case invalidURL = 20000
    
    /// The downloading task is cancelled before started.
    case downloadCancelledBeforeStarting = 30000
}

/// Key will be used in the `userInfo` of `.invalidStatusCode`
public let KingfisherErrorStatusCodeKey = "statusCode"


/// ImageDownloaderDelegate
protocol ImageDownloaderDelegate: class {
    func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?)
    
    func imageDownloader(_ downloader: ImageDownloader, didFinishDownloadingImageForURL url: URL, with response: URLResponse?, error: Error?)
    
    func imageDownloader(_ downloader: ImageDownloader, didDownload image: Image, for url: URL, with response: URLResponse?)
    
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data?
    
    func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool
}

extension ImageDownloaderDelegate {
    func imageDownloader(_ downloader: ImageDownloader, willDownloadImageForURL url: URL, with request: URLRequest?) {}
    
    func imageDownloader(_ downloader: ImageDownloader, didFinishDownloadingImageForURL url: URL, with response: URLResponse?, error: Error?) {}
    
    func imageDownloader(_ downloader: ImageDownloader, didDownload image: Image, for url: URL, with response: URLResponse?) {}
    
    func imageDownloader(_ downloader: ImageDownloader, didDownload data: Data, for url: URL) -> Data? {
        return data
    }
    
    func isValidStatusCode(_ code: Int, for downloader: ImageDownloader) -> Bool {
        return (200..<400).contains(code)
    }
}

/// AuthenticationChallengeResponsable
protocol AuthenticationChallengeResponsable: class {
    func downloader(_ downloader: ImageDownloader, didReceive challege: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    func downloader(_ downloader: ImageDownloader, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

extension AuthenticationChallengeResponsable {
    func downloader(_ downloader: ImageDownloader, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let trustedHosts = downloader.trustedHosts, trustedHosts.contains(challenge.protectionSpace.host) {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        completionHandler(.performDefaultHandling, nil)
    }
    
    func downloader(_ downloader: ImageDownloader, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        completionHandler(.performDefaultHandling, nil)
    }
}

class ImageDownloader {
    class ImageFetchLoad {
        var contents = [(callback: CallbackPair, options: KingfisherOptionsInfo)]()
        var responseData = NSMutableData()
        
        var downloadTaskCount = 0
        var downloadTask: RetrieveImageDownloadTask?
        var cancelSemaphore: DispatchSemaphore?
    }
    
    var downloadTimeout: TimeInterval = 15.0
    
    var trustedHosts: Set<String>?
    
    var sessionConfiguration = URLSessionConfiguration.ephemeral {
        didSet {
            session?.invalidateAndCancel()
            session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: nil)
        }
    }
    
    /// 是否使用管道请求
    var requestsUsePipelining = false
    
    fileprivate let sessionHandler: ImageDownloaderSessionHandler
    
    fileprivate var session: URLSession?
    
    weak var delegate: ImageDownloaderDelegate?
    
    weak var authenticationChallengeResponder: AuthenticationChallengeResponsable?
    
    let barrierQueue: DispatchQueue
    let processQueue: DispatchQueue
    let cancelQueue: DispatchQueue
    
    typealias CallbackPair = (progressBlock: ImageDownloaderProgressBlock?, completionHandler: ImageDownloaderCompletionHandler?)
    
    var fetchLoads = [URL: ImageFetchLoad]()
    
    static let `default` = ImageDownloader(name: "default")
    
    init(name: String) {
        if name.isEmpty {
            fatalError("[Kingfisher] You should specify a name for the downloader. A downloader with empty name is not permitted.")
        }
        
        barrierQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Barrier.\(name)", attributes: .concurrent)
        processQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Process.\(name)", attributes: .concurrent)
        cancelQueue = DispatchQueue(label: "com.onevcat.Kingfisher.ImageDownloader.Cancel.\(name)")
        
        sessionHandler = ImageDownloaderSessionHandler()
        
        authenticationChallengeResponder = sessionHandler
        session = URLSession(configuration: sessionConfiguration, delegate: sessionHandler, delegateQueue: .main)
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
    
    func fetchLoad(for url: URL) -> ImageFetchLoad? {
        var fetchLoad: ImageFetchLoad?
        barrierQueue.sync(flags: .barrier) {
            fetchLoad = fetchLoads[url]
        }
        return fetchLoad
    }
    
    @discardableResult
    func downloadImage(with url: URL,
                       retrieveImageTask: RetrieveImageTask? = nil,
                       options: KingfisherOptionsInfo? = nil,
                       progressBlock: ImageDownloaderProgressBlock? = nil,
                       completionHandler: ImageDownloaderCompletionHandler? = nil) -> RetrieveImageDownloadTask? {
        if let retrieveImageTask = retrieveImageTask, retrieveImageTask.cancelledBeforeDownloadStarting {
            completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.downloadCancelledBeforeStarting.rawValue, userInfo: nil), nil, nil)
            return nil
        }
        
        let timeout = self.downloadTimeout == 0.0 ? 15.0 : self.downloadTimeout
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpShouldUsePipelining = requestsUsePipelining
        
        if let modifier = options?.modifier {
            guard let r = modifier.modified(for: request) else {
                completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.downloadCancelledBeforeStarting.rawValue, userInfo: nil), nil, nil)
                return nil
            }
            request = r
        }
        
        //  保证absoluteString不为空
        guard let url = request.url, !url.absoluteString.isEmpty else {
            completionHandler?(nil, NSError(domain: KingfisherErrorDomain, code: KingfisherError.invalidURL.rawValue, userInfo: nil), nil, nil)
            return nil
        }
        
        var downloadTask: RetrieveImageDownloadTask?
        
        setup(progressBlock: progressBlock, with: completionHandler, for: url, options: options) { (session, fetchLoad) in
            if fetchLoad.downloadTask == nil {
                let dataTask = session.dataTask(with: request)
                
                fetchLoad.downloadTask = RetrieveImageDownloadTask(internalTask: dataTask, ownerDownloader: self)
                
                dataTask.priority = options?.downloadPriority ?? URLSessionTask.defaultPriority
                self.delegate?.imageDownloader(self, willDownloadImageForURL: url, with: request)
            }
            
            fetchLoad.downloadTaskCount += 1
            downloadTask = fetchLoad.downloadTask
            
            retrieveImageTask?.downloadTask = downloadTask
        }
        
        return downloadTask
    }
}

// FIXME: -重点学习
extension ImageDownloader {
    //MARK:- 创建下载任务
    func setup(progressBlock: ImageDownloaderProgressBlock?, with completionHandler: ImageDownloaderCompletionHandler?, for url: URL, options: KingfisherOptionsInfo?, started: @escaping ((URLSession, ImageFetchLoad) -> Void)) {
        func prepareFetchLoad() {
            barrierQueue.sync(flags: .barrier) {
                let loadObjectForURL = fetchLoads[url] ?? ImageFetchLoad()
                let callbackPair = (progressBlock: progressBlock, completionHandler: completionHandler)
                
                loadObjectForURL.contents.append((callbackPair, options ?? KingfisherEmptyOptionsInfo ))
                fetchLoads[url] = loadObjectForURL
                
                if let seesion = session {
                    started(seesion, loadObjectForURL)
                }
            }
        }
        
        if let fetchLoad = fetchLoad(for: url), fetchLoad.downloadTaskCount == 0 {
            if fetchLoad.cancelSemaphore == nil {
                fetchLoad.cancelSemaphore = DispatchSemaphore(value: 0)
            }
            cancelQueue.async {
                _ = fetchLoad.cancelSemaphore?.wait(timeout: .distantFuture)
                fetchLoad.cancelSemaphore = nil
                prepareFetchLoad()
            }
        }else {
            prepareFetchLoad()
        }
    }
    
    //MARK:- 取消下载任务
    private func cancelTaskImpl(_ task: RetrieveImageDownloadTask, fetchLoad: ImageFetchLoad? = nil, ignoreTaskCount: Bool = false) {
        func getFetchLoad(from task: RetrieveImageDownloadTask) -> ImageFetchLoad? {
            guard let URL = task.internalTask.originalRequest?.url, let imageFetchLoad = self.fetchLoads[URL] else {
                return nil
            }
            return imageFetchLoad
        }
        
        guard let imageFetchLoad = fetchLoad ?? getFetchLoad(from: task) else {
            return
        }
        
        imageFetchLoad.downloadTaskCount -= 1
        if ignoreTaskCount || imageFetchLoad.downloadTaskCount == 0 {
            task.internalTask.cancel()
        }
    }
    
    func cancel(_ task: RetrieveImageDownloadTask) {
        barrierQueue.sync(flags: .barrier) {
            cancelTaskImpl(task)
        }
    }
    
    func cancelAll() {
        barrierQueue.sync(flags: .barrier) {
            fetchLoads.forEach({ v in
                let fetchLoad = v.value
                guard let task = fetchLoad.downloadTask else { return }
                cancelTaskImpl(task, fetchLoad: fetchLoad, ignoreTaskCount: true)
            })
        }
    }
}

final class ImageDownloaderSessionHandler: NSObject, URLSessionDataDelegate, AuthenticationChallengeResponsable {
    var downloadHolder: ImageDownloader?
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let downloader = downloadHolder else {
            completionHandler(.cancel)
            return
        }
        
        if let statusCode = (response as? HTTPURLResponse)?.statusCode, let url = dataTask.originalRequest?.url, !(downloader.delegate ?? downloader).isValidStatusCode(statusCode, for: downloader) {
            let error = NSError(domain: KingfisherErrorDomain,
                                code: KingfisherError.invalidStatusCode.rawValue,
                                userInfo: [KingfisherErrorStatusCodeKey: statusCode, NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)])
            
            if let downloader = downloadHolder {
                downloader.delegate?.imageDownloader(downloader, didFinishDownloadingImageForURL: url, with: response, error: error)
            }
            
            callCompletionHandlerFailure(error: error, url: url)
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let downloader = downloadHolder else {
            return
        }
        
        if let url = dataTask.originalRequest?.url, let fetchLoad = downloader.fetchLoad(for: url) {
            fetchLoad.responseData.append(data)
            
            if let expectedLength = dataTask.response?.expectedContentLength {
                for content in fetchLoad.contents {
                    DispatchQueue.main.async {
                        content.callback.progressBlock?(Int64(fetchLoad.responseData.length), expectedLength)
                    }
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else {
            return
        }
        
        if let downloader = downloadHolder {
            downloader.delegate?.imageDownloader(downloader, didFinishDownloadingImageForURL: url, with: task.response, error: error)
        }
        
        guard error == nil else {
            callCompletionHandlerFailure(error: error!, url: url)
            return
        }
        
        processImage(for: task, url: url)
    }
    
    /**
     This method is exposed since the compiler requests. Do not call it.
     */
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let downloader = downloadHolder else {
            return
        }
        
        downloader.authenticationChallengeResponder?.downloader(downloader, didReceive: challenge, completionHandler: completionHandler)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let downloader = downloadHolder else {
            return
        }
        
        downloader.authenticationChallengeResponder?.downloader(downloader, task: task, didReceive: challenge, completionHandler: completionHandler)
    }
    
    private func cleanFetchLoad(for url: URL) {
        guard  let downloader = downloadHolder else {
            return
        }
        
        downloader.barrierQueue.sync(flags: .barrier) {
            downloader.fetchLoads.removeValue(forKey: url)
            if downloader.fetchLoads.isEmpty {
                downloadHolder = nil
            }
        }
    }
    
    private func callCompletionHandlerFailure(error: Error, url: URL) {
        guard let downloader = downloadHolder, let fetchLoad = downloader.fetchLoad(for: url) else {
            return
        }
        
        cleanFetchLoad(for: url)
        
        var leftSignal: Int
        repeat {
            leftSignal = fetchLoad.cancelSemaphore?.signal() ?? 0
        }while leftSignal != 0
        
        for content in fetchLoad.contents {
            content.options.callbackDispatchQueue.safeAsync {
                content.callback.completionHandler?(nil, error as NSError, url, nil)
            }
        }
    }
    
    private func processImage(for task: URLSessionTask, url: URL) {
        guard let downloader = downloadHolder else {
            return
        }
        
        downloader.processQueue.async {
            guard let fetchLoad = downloader.fetchLoad(for: url) else {
                return
            }
            
            self.cleanFetchLoad(for: url)
            
            let data: Data?
            let fetchedData = fetchLoad.responseData as Data
            
            if let delegate = downloader.delegate {
                data = delegate.imageDownloader(downloader, didDownload: fetchedData, for: url)
            }else {
                data = fetchedData
            }
            
            var imageCache: [String: Image] = [:]
            
            for content in fetchLoad.contents {
                let options = content.options
                let completionHandler = content.callback.completionHandler
                let callbackQueue = options.callbackDispatchQueue
                
                let processor = options.processor
                var image = imageCache[processor.identifier]
                if let data = data, image == nil {
                    image = processor.process(item: .data(data), options: options)
                    imageCache[processor.identifier] = image
                }
                
                if let image = image {
                    downloader.delegate?.imageDownloader(downloader, didDownload: image, for: url, with: task.response)
                    
                    let imageModifier = options.imageModifier
                    let finalImage = imageModifier.modify(image)
                    
                    if options.backgroundDecode {
                        let decodedImage = finalImage.kf.decoded
                        callbackQueue.safeAsync { completionHandler?(decodedImage, nil, url, data) }
                    }else {
                        callbackQueue.safeAsync { completionHandler?(finalImage, nil, url, data) }
                    }
                }else {
                    if let res = task.response as? HTTPURLResponse, res.statusCode == 304 {
                        let notModified = NSError(domain: KingfisherErrorDomain, code: KingfisherError.notModified.rawValue, userInfo: nil)
                        completionHandler?(nil, notModified, url, nil)
                        continue
                    }
                    
                    let badData = NSError(domain: KingfisherErrorDomain, code: KingfisherError.badData.rawValue, userInfo: nil)
                    callbackQueue.safeAsync { completionHandler?(nil, badData, url, nil) }
                }
            }
        }
    }
}

extension ImageDownloader: ImageDownloaderDelegate {}
