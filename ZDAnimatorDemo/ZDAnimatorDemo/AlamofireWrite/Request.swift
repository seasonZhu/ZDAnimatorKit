//
//  Request.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/12/7.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

public class SessionManager {
    
}

public protocol RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest
}

public typealias RequestRetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

public protocol RequestRetrier {
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion)
}

protocol TaskConvertible {
    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask
}

public typealias HTTPHeaders = [String: String]

open class Request {
    public typealias ProgressHandler = (Progress) -> Void
    
    enum RequestTask {
        case data(TaskConvertible?, URLSessionTask?)
        case download(TaskConvertible?, URLSessionTask?)
        case upload(TaskConvertible?, URLSessionTask?)
        case stream(TaskConvertible?, URLSessionTask?)
    }
    
    open internal(set) var delegate: TaskDelegate {
        get {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            return taskDelegate
        }
        set {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            taskDelegate = newValue
        }
    }
    
    open var task: URLSessionTask? { return delegate.task }
    
    public let session: URLSession
    
    open var request: URLRequest? { return task?.originalRequest  }
    
    open var response: HTTPURLResponse? { return task?.response as? HTTPURLResponse }
    
    open internal(set) var retryCount: UInt = 0
    
    let originalTask: TaskConvertible?
    
    var startTime: CFAbsoluteTime?
    var endTime: CFAbsoluteTime?
    
    //  一个放着闭包的数组
    var validations: [() -> Void] = []
    
    private var taskDelegate: TaskDelegate
    private var taskDelegateLock = NSLock()
    
    // MARK: Lifecycle
    init(session: URLSession, requestTask: RequestTask, error: Error? = nil) {
        self.session = session
        switch requestTask {
        case .data(let originalTask, let task):
            taskDelegate = DataTaskDelegate(task: task)
            self.originalTask = originalTask
        case .download(let originalTask, let task):
            taskDelegate = DownloadTaskDelegate(task: task)
            self.originalTask = originalTask
        case .upload(let originalTask, let task):
            taskDelegate = UploadTaskDelegate(task: task)
            self.originalTask = originalTask
        case .stream(let originalTask, let task):
            taskDelegate = TaskDelegate(task: task)
            self.originalTask = originalTask
        }
        
        delegate.error = error
        delegate.queue.addOperation {
            self.endTime = CFAbsoluteTimeGetCurrent()
        }
    }
    
    ///  认证 虽然我压根就没搞过认证
    @discardableResult
    open func authenticate(user: String, password: String, persistence: URLCredential.Persistence = .forSession) -> Self {
        let credential = URLCredential(user: user, password: password, persistence: persistence)
        return authenticate(usingCredential: credential)
    }
    
    @discardableResult
    open func authenticate(usingCredential credential: URLCredential) -> Self {
        delegate.credential = credential
        return self
    }
    
    open class func authorizationHeader(user: String, password: String) -> (key: String, value: String)? {
        guard let data = "\(user):\(password)".data(using: .utf8) else { return nil }
        
        let credential = data.base64EncodedString(options: [])
        
        return (key: "Authorization", value: "Basic \(credential)")
    }
    
    /// 任务中断 取消 继续
    open func resume() {
        guard let task = task else {  delegate.queue.isSuspended = false; return }
        
        if startTime == nil {
            startTime = CFAbsoluteTimeGetCurrent()
        }
        
        task.resume()
        
        NotificationCenter.default.post(name: Notification.Name.Task.DidResume, object: self, userInfo: [Notification.Key.Task: task])
    }
    
    open func suspend() {
        guard let task = task else { return }
        
        task.suspend()
        
        NotificationCenter.default.post(
            name: Notification.Name.Task.DidSuspend,
            object: self,
            userInfo: [Notification.Key.Task: task]
        )
    }
    
    open func cancel() {
        guard let task = task else { return }
        
        task.cancel()
        
        NotificationCenter.default.post(
            name: Notification.Name.Task.DidCancel,
            object: self,
            userInfo: [Notification.Key.Task: task]
        )
    }
}


// MARK: - 打印Request获取的信息
extension Request: CustomStringConvertible {
    /// The textual representation used when written to an output stream, which includes the HTTP method and URL, as
    /// well as the response status code if a response has been received.
    open var description: String {
        var components: [String] = []
        
        if let HTTPMethod = request?.httpMethod {
            components.append(HTTPMethod)
        }
        
        if let urlString = request?.url?.absoluteString {
            components.append(urlString)
        }
        
        if let response = response {
            components.append("(\(response.statusCode))")
        }
        
        return components.joined(separator: " ")
    }
}

extension Request: CustomDebugStringConvertible {
    /// The textual representation used when written to an output stream, in the form of a cURL command.
    open var debugDescription: String {
        return cURLRepresentation()
    }
    
    func cURLRepresentation() -> String {
        var components = ["$ curl -v"]
        
        guard let request = self.request,
            let url = request.url,
            let host = url.host
            else {
                return "$ curl command could not be created"
        }
        
        if let httpMethod = request.httpMethod, httpMethod != "GET" {
            components.append("-X \(httpMethod)")
        }
        
        if let credentialStorage = self.session.configuration.urlCredentialStorage {
            let protectionSpace = URLProtectionSpace(
                host: host,
                port: url.port ?? 0,
                protocol: url.scheme,
                realm: host,
                authenticationMethod: NSURLAuthenticationMethodHTTPBasic
            )
            
            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else { continue }
                    components.append("-u \(user):\(password)")
                }
            } else {
                if let credential = delegate.credential, let user = credential.user, let password = credential.password {
                    components.append("-u \(user):\(password)")
                }
            }
        }
        
        if session.configuration.httpShouldSetCookies {
            if
                let cookieStorage = session.configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty
            {
                let string = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }
                
                #if swift(>=3.2)
                components.append("-b \"\(string[..<string.index(before: string.endIndex)])\"")
                #else
                components.append("-b \"\(string.substring(to: string.characters.index(before: string.endIndex)))\"")
                #endif
            }
        }
        
        var headers: [AnyHashable: Any] = [:]
        
        if let additionalHeaders = session.configuration.httpAdditionalHeaders {
            for (field, value) in additionalHeaders where field != AnyHashable("Cookie") {
                headers[field] = value
            }
        }
        
        if let headerFields = request.allHTTPHeaderFields {
            for (field, value) in headerFields where field != "Cookie" {
                headers[field] = value
            }
        }
        
        for (field, value) in headers {
            let escapedValue = String(describing: value).replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(field): \(escapedValue)\"")
        }
        
        if let httpBodyData = request.httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
            
            components.append("-d \"\(escapedBody)\"")
        }
        
        components.append("\"\(url.absoluteString)\"")
        
        return components.joined(separator: " \\\n\t")
    }
}

open class DataRequeut: Request {
    
    struct Requetable: TaskConvertible  {
        
        let urlRequest: URLRequest
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                let urlRequest = try self.urlRequest.adapt(using: adapter)
                
                //  可以这样返回
                return queue.sync {
                    session.dataTask(with: urlRequest)
                }
            } catch {
                throw AdaptError(error: error)
            }
        }
    }
    
    open override var request: URLRequest? {
        if let request = super.request {
            return request
        }
        
        if let requestable = originalTask as? Requetable {
            return requestable.urlRequest
        }
        
        return nil
    }
    
    open var progress: Progress {
        return dataDelegate.progress
    }
    
    var dataDelegate: DataTaskDelegate {
        return delegate as! DataTaskDelegate
    }
    
    @discardableResult
    open func stream(closure: ((Data) -> ())? = nil) -> Self {
        dataDelegate.dataStream = closure
        return self
    }
    
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        dataDelegate.progressHandler = (closure, queue)
        return self
    }
}

open class DownloadRequest: Request {
    public struct DownloadOptions: OptionSet {
        public let rawValue: UInt
        
        public static let createIntermediateDirectories = DownloadOptions(rawValue: 1 << 0)
        
        public static let removePreviousFile = DownloadOptions(rawValue: 1 << 1)
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    public typealias DownloadFileDestination = (_ temporaryURL: URL, _ response: HTTPURLResponse) -> (destinationURL: URL, options: DownloadOptions)
    
    enum Downloadable: TaskConvertible {
        case request(URLRequest)
        case resumeData(Data)
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                let task: URLSessionTask
                switch self {
                case let .request(urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync {
                        session.downloadTask(with: urlRequest)
                    }
                
                case let .resumeData(resumeData):
                    task = queue.sync {
                        session.downloadTask(withResumeData: resumeData)
                    }
                }
                return task
            } catch {
                throw AdaptError(error: error)
            }
        }
    }
    
    open override var request: URLRequest? {
        if let request = super.request {
            return request
        }
        
        if let downloadable = originalTask as? Downloadable, case let .request(urlRequest) = downloadable {
            return urlRequest
        }
        
        return nil
    }
    
    open var resumeData: Data? { return downloadDelegate.resumeData }
    
    open var progress: Progress { return downloadDelegate.progress }
    
    var downloadDelegate: DownloadTaskDelegate {
        return delegate as! DownloadTaskDelegate
    }
    
    open override func cancel() {
        downloadDelegate.downloadTask.cancel { (data) in
            self.downloadDelegate.resumeData = data
        }
        
        NotificationCenter.default.post(name: Notification.Name.Task.DidCancel, object: self, userInfo: [Notification.Key.Task: task as Any])
    }
    
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = .main, closure: @escaping ProgressHandler) -> Self {
        downloadDelegate.progressHandler = (closure, queue)
        return self
    }
    
    open class func suggestedDownloadDestination(for directory: FileManager.SearchPathDirectory = .documentDirectory, in domain: FileManager.SearchPathDomainMask = .userDomainMask) -> DownloadFileDestination {
        return { temporaryURL, response in
            let directoryURLs = FileManager.default.urls(for: directory, in: domain)
            
            if !directoryURLs.isEmpty {
                return (directoryURLs[0].appendingPathComponent(response.suggestedFilename!), [])
            }
            
            return (temporaryURL, [])
            
        }
    }
}

open class UploadRequest: DataRequeut {
    enum Uploadable: TaskConvertible {
        
        case data(Data, URLRequest)
        case file(URL, URLRequest)
        case stream(InputStream, URLRequest)
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            do {
                let task: URLSessionTask
                
                switch self {
                case let .data(data, urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync {
                        session.uploadTask(with: urlRequest, from: data)
                    }
                case let .file(url, urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync {
                        session.uploadTask(with: urlRequest, fromFile: url)
                    }
                case let .stream(_, urlRequest):
                    let urlRequest = try urlRequest.adapt(using: adapter)
                    task = queue.sync {
                        session.uploadTask(withStreamedRequest: urlRequest)
                    }
                }
                
                return task
                
            } catch  {
                throw AdaptError(error: error)
            }
        }
    }
    
    open override var request: URLRequest? {
        if let request = super.request { return request }
        
        guard let uploadable = originalTask as? Uploadable else { return nil }
        
        switch uploadable {
        case .data(_, let urlRequest), .file(_, let urlRequest), .stream(_, let urlRequest):
            return urlRequest
        }
    }
    
    open var uploadProgress: Progress { return uploadDelegate.uploadProgress }
    
    var uploadDelegate: UploadTaskDelegate { return delegate as! UploadTaskDelegate }
    
    @discardableResult
    open func uploadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        uploadDelegate.uploadProgressHandler = (closure, queue)
        return self
    }
}

#if !os(watchOS)
@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)

open class StreamRequest: Request {
    
    enum Streamable: TaskConvertible {
        case stream(hostName: String, port: Int)
        case netService(NetService)
        
        func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
            let task: URLSessionTask
            
            //  这里的写法和原版的不同 原版的let 在枚举前面 枚举里面直接跟着参数 原版的写法更为简单
            switch self {
            case .stream(let hostName, let port):
                task = queue.sync {
                    session.streamTask(withHostName: hostName, port: port)
                }
            case .netService(let netService):
                task = queue.sync {
                    session.streamTask(with: netService)
                }
            }
            
            return task
        }
    }
}

#endif
