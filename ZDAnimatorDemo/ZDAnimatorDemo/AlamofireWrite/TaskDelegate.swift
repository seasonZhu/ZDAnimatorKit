//
//  TaskDelegate.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/12/14.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

open class TaskDelegate: NSObject {
    public let queue: OperationQueue
    
    public var data: Data? { return nil }
    
    public var error: Error?
    
    var task: URLSessionTask? {
        set {
            taskLock.lock()
            defer {
                taskLock.unlock()
            }
            _task = newValue
        }get {
            taskLock.lock()
            defer {
                taskLock.unlock()
            }
            return _task
        }
    }
    
    var initialResponseTime: CFAbsoluteTime?
    
    var credential: URLCredential?
    
    var metrics: AnyObject?
    
    private var _task: URLSessionTask? {
        didSet {
            reset()
        }
    }
    
    private let taskLock = NSLock()
    
    init(task: URLSessionTask?) {
        _task = task
        
        self.queue = {
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.isSuspended = true
            operationQueue.qualityOfService = .utility
            
            return operationQueue
        }()
    }
    
    func reset() {
        error = nil
        initialResponseTime = nil
    }
    
    // MARK: URLSessionTaskDelegate 我感觉就是把URLSessionDelegate自己手写一遍
    
    //  函数的闭包形式
    var taskWillPerformHTTPRedirection: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest?)?
    var taskDidReceiveChallenge: ((URLSession, URLSessionTask, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    var taskNeedNewBodyStream: ((URLSession, URLSessionTask) -> InputStream?)?
    var taskDidCompleteWithError: ((URLSession, URLSessionTask, Error?) -> Void)?
    
    ///  这个下面的方法和URLSessionTaskDelegatez一摸一样
    @objc(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void) {
        var redirectRequest: URLRequest? = request
        if let taskWillPerformHTTPRedirection = taskWillPerformHTTPRedirection {
            redirectRequest = taskWillPerformHTTPRedirection(session, task, response, request)
        }
        
        completionHandler(redirectRequest)
    }
    
    @objc(URLSession:task:didReceiveChallenge:completionHandler:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if let taskDidReceiveChallenge = taskDidReceiveChallenge {
            (disposition, credential) = taskDidReceiveChallenge(session, task, challenge)
        }else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host
            
            ///  这个地方后续继续写
        }else {
            if challenge.previousFailureCount > 0 {
                disposition = .rejectProtectionSpace
            }else {
                credential = self.credential ?? session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                
                if credential != nil {
                    disposition = .useCredential
                }
            }
        }
        
        completionHandler(disposition, credential)
    }
    
    @objc(URLSession:task:needNewBodyStream:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        var bodyStream: InputStream?
        
        if let taskNeedNewBodyStream = taskNeedNewBodyStream {
            bodyStream = taskNeedNewBodyStream(session, task)
        }
        
        completionHandler(bodyStream)
    }
    
    @objc(URLSession:task:didCompleteWithError:)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let taskDidCompleteWithError = taskDidCompleteWithError {
            taskDidCompleteWithError(session, task, error)
        }else {
            if let error = error {
                if self.error == nil {
                    self.error = error
                }
                
                if let downloadDelegat = self as? DownloadTaskDelegate,
                    let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    downloadDelegat.resumeData = resumeData
                }
            }
            
            queue.isSuspended = false
        }
    }
}

class DataTaskDelegate: TaskDelegate, URLSessionDataDelegate {
    var dataTask: URLSessionDataTask { return task as! URLSessionDataTask }
    
    override var data: Data? {
        if dataStream != nil {
            return nil
        }else {
            return mutableData
        }
    }
    
    var progress: Progress
    //  一个带有闭包的元组
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    var dataStream: ((_ data: Data) -> Void)?
    
    private var totalBytesReceived: Int64 = 0
    private var mutableData: Data
    
    private var expectedContentLength: Int64?
    
    override init(task: URLSessionTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: 0)
        
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        totalBytesReceived = 0
        mutableData = Data()
        expectedContentLength = nil
    }
    
    // MARK: URLSessionDataDelegate
    
    var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
    var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
    var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        var disposition: URLSession.ResponseDisposition = .allow
        
        expectedContentLength = response.expectedContentLength
        
        if let dataTaskDidReceiveResponse = dataTaskDidReceiveResponse {
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }
        
        completionHandler(disposition)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        dataTaskDidBecomeDownloadTask?(session, dataTask, downloadTask)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if initialResponseTime == nil {
            initialResponseTime = CFAbsoluteTimeGetCurrent()
        }
        
        if let dataTaskDidReceiveData = dataTaskDidReceiveData {
            dataTaskDidReceiveData(session, dataTask, data)
        }else {
            if let dataStream = dataStream {
                dataStream(data)
            }else {
                mutableData.append(data)
            }
            
            let bytesReceived = Int64(data.count)
            totalBytesReceived += bytesReceived
            
            let totalBytesExpected = dataTask.response?.expectedContentLength
            progress.totalUnitCount = totalBytesExpected ?? NSURLSessionTransferSizeUnknown
            progress.completedUnitCount = totalBytesReceived
            
            //  这个想法真的是吊炸天
            if let progressHandler = progressHandler {
                progressHandler.queue.async {
                    progressHandler.closure(self.progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Void) {
        var cachedResponse: CachedURLResponse? = proposedResponse
        
        if let dataTaskWillCacheResponse = dataTaskWillCacheResponse {
            cachedResponse = dataTaskWillCacheResponse(session, dataTask, proposedResponse)
        }
        
        completionHandler(cachedResponse)
    }
}

/// 下载的代理稍后写 和Request有关系
class DownloadTaskDelegate: TaskDelegate, URLSessionDownloadDelegate {
    
    var downloadTask: URLSessionDownloadTask { return task as! URLSessionDownloadTask }
    
    var progress: Progress
    var progressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    var resumeData: Data?
    override var data: Data? { return resumeData }
    
    var destination: DownloadRequest.DownloadFileDestination?
    
    var temporaryURL: URL?
    var destinationURL: URL?
    
    var fileURL: URL? {
        return destination != nil ? destinationURL : temporaryURL
    }

    override init(task: URLSessionTask?) {
        progress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        resumeData = nil
    }
    
    // MARK: URLSessionDownloadDelegate
    
    var downloadTaskDidFinishDownloadingToURL: ((URLSession, URLSessionDownloadTask, URL) -> URL)?
    var downloadTaskDidWriteData: ((URLSession, URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
    var downloadTaskDidResumeAtOffset: ((URLSession, URLSessionDownloadTask, Int64, Int64) -> Void)?
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        temporaryURL = location
        guard let destination = destination, let response = downloadTask.response as? HTTPURLResponse else { return }
        let result = destination(location, response)
        let destinationURL = result.destinationURL
        let options = result.options
        
        do {
            if options.contains(.removePreviousFile), FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            if options.contains(.createIntermediateDirectories) {
                let directory = destinationURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
            
        } catch  {
            self.error = error
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if initialResponseTime == nil {
            initialResponseTime = CFAbsoluteTimeGetCurrent()
        }
        
        if let downloadTaskDidWriteData = downloadTaskDidWriteData {
            downloadTaskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        }else {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
            
            if let progressHandler = progressHandler {
                progressHandler.queue.async {
                    progressHandler.closure(self.progress)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        if let downloadTaskDidResumeAtOffset = downloadTaskDidResumeAtOffset {
            downloadTaskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes)
        } else {
            progress.totalUnitCount = expectedTotalBytes
            progress.completedUnitCount = fileOffset
        }
    }
}


class UploadTaskDelegate: DataTaskDelegate {
    var uploadTask: URLSessionUploadTask { return task as! URLSessionUploadTask }
    
    var uploadProgress: Progress
    var uploadProgressHandler: (closure: Request.ProgressHandler, queue: DispatchQueue)?
    
    override init(task: URLSessionTask?) {
        // 注意这里没有用self.uploadProgress 虽然用也可以 这个也更加进一步说明 先初始化自己的 在初始化父类的
        uploadProgress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        uploadProgress = Progress(totalUnitCount: 0)
    }
    
    // MARK: URLSessionTaskDelegate
    
    var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if initialResponseTime == nil {
            initialResponseTime = CFAbsoluteTimeGetCurrent()
        }
        
        if let taskDidSendBodyData = taskDidSendBodyData {
            taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        }else {
            uploadProgress.totalUnitCount = totalBytesExpectedToSend
            uploadProgress.completedUnitCount = totalBytesSent
            
            if let uploadProgressHandler = uploadProgressHandler {
                uploadProgressHandler.queue.async {
                    uploadProgressHandler.closure(self.uploadProgress)
                }
            }
        }
    }
}
