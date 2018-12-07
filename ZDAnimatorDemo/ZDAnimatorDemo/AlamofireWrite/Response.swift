//
//  Response.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/28.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

/// 默认的数据响应
public struct DefaultDataResponse {
    public let request: URLRequest?
    
    public let response: HTTPURLResponse?
    
    public let data: Data?
    
    public let error: Error?
    
    public let timeline: Timeline
    
    var _metrics: AnyObject?
    
    public init(request: URLRequest,
                response: HTTPURLResponse,
                data: Data?,
                error: Error?,
                timeline: Timeline = Timeline(),
                metrics: AnyObject? = nil) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.timeline = timeline
    }
}

/// 泛型式的数据响应
public struct DataResponse<Value> {
    public let request: URLRequest?
    
    public let response: HTTPURLResponse?
    
    public let data: Data?
    
    public let result: Result<Value>
    
    public let timeline: Timeline
    
    public var value: Value? { return result.value }
    
    public var error: Error? { return result.error }
    
    var _metrics: AnyObject?
    
    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                data: Data?,
                result: Result<Value>,
                timeline: Timeline = Timeline()) {
        self.request = request
        self.response = response
        self.data = data
        self.result = result
        self.timeline = timeline
    }
}

extension DataResponse: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return result.debugDescription
    }
    
    public var debugDescription: String {
        var output: [String] = []
        
        output.append(request != nil ? "[Request]: \(request!.httpMethod ?? "GET")\(request!)" : "[Request]: nil")
        output.append(response != nil ? "[Response]: \(response!)" : "[Response]: nil")
        output.append("[Data]: \(data?.count ?? 0) bytes")
        output.append("[Result]: \(result.debugDescription)")
        output.append("[Timeline]: \(timeline.debugDescription)")
        
        return output.joined(separator: "\n")
    }
}

extension DataResponse {
    public func map<T>(_ transform: (Value) -> T) -> DataResponse<T> {
        var response = DataResponse<T>(request: request, response: self.response, data: data, result: result.map(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
    
    public func flatMap<T>(_ transform: (Value) throws -> T) -> DataResponse<T> {
        var response = DataResponse<T>(request: request, response: self.response, data: data, result: result.flatMap(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
    
    public func mapError<E: Error>(_ transform: (Error) -> E) -> DataResponse {
        var response = DataResponse(request: request, response: self.response, data: data, result: result.mapError(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
    
    public func flatMapError<E: Error>(_ transform: (Error) throws -> E) -> DataResponse {
        var response = DataResponse(request: request, response: self.response, data: data, result: result.flatMapError(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
}

public struct DefaultDownloadResponse {
    public let request: URLRequest?
    
    public let response: HTTPURLResponse?
    
    public let temporaryURL: URL?
    
    public let destinationURL: URL?
    
    public let resumeData: Data?
    
    public let error: Error?
    
    public let timeline: Timeline
    
    var _metrics: AnyObject?
    
    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                temporaryURL: URL?,
                destinationURL: URL?,
                resumeData: Data?,
                error: Error,
                timeline: Timeline = Timeline(),
                metrics: AnyObject? = nil) {
        self.request = request
        self.response = response
        self.temporaryURL = temporaryURL
        self.destinationURL = destinationURL
        self.resumeData = resumeData
        self.error = error
        self.timeline = timeline
    }
}

public struct DownloadResponse<Value> {
    public let request: URLRequest?
    
    public let response: HTTPURLResponse?
    
    public let temporaryURL: URL?
    
    public let destinationURL: URL?
    
    public let resumeData: Data?
    
    public let result: Result<Value>
    
    public let timeline: Timeline
    
    public var value: Value? { return result.value }
    
    public var error: Error? { return result.error }
    
    var _metrics: AnyObject?
    
    public init(request: URLRequest?,
                response: HTTPURLResponse?,
                temporaryURL: URL?,
                destinationURL: URL?,
                resumeData: Data?,
                result: Result<Value>,
                timeline: Timeline = Timeline(),
                metrics: AnyObject? = nil) {
        self.request = request
        self.response = response
        self.temporaryURL = temporaryURL
        self.destinationURL = destinationURL
        self.resumeData = resumeData
        self.result = result
        self.timeline = timeline
    }
}

extension DownloadResponse: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return result.debugDescription
    }
    
    public var debugDescription: String {
        var output: [String] = []
        
        output.append(request != nil ? "[Request]: \(request!.httpMethod ?? "GET") \(request!)" : "[Request]: nil")
        output.append(response != nil ? "[Response]: \(response!)" : "[Response]: nil")
        output.append("[TemporaryURL]: \(temporaryURL?.path ?? "nil")")
        output.append("[DestinationURL]: \(destinationURL?.path ?? "nil")")
        output.append("[ResumeData]: \(resumeData?.count ?? 0) bytes")
        output.append("[Result]: \(result.debugDescription)")
        output.append("[Timeline]: \(timeline.debugDescription)")
        
        return output.joined(separator: "\n")
    }

}

extension DownloadResponse {
    public func map<T>(_ transform: (Value) -> T) -> DownloadResponse<T> {
        var response = DownloadResponse<T>(request: request, response: self.response, temporaryURL: temporaryURL, destinationURL: destinationURL, resumeData: resumeData, result: result.map(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
    
    public func flatMap<T>(_ transform: (Value) throws -> T) -> DownloadResponse<T> {
        var response = DownloadResponse<T>(request: request, response: self.response, temporaryURL: temporaryURL, destinationURL: destinationURL, resumeData: resumeData, result: result.flatMap(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
    
    public func mapError<E: Error>(_ transform: (Error) -> E) -> DownloadResponse {
        var response = DownloadResponse(request: request, response: self.response, temporaryURL: temporaryURL, destinationURL: destinationURL, resumeData: resumeData, result: result.mapError(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
    
    public func flatMapError<E: Error>(_ transform: (Error) throws -> E) -> DownloadResponse {
        var response = DownloadResponse(request: request, response: self.response, temporaryURL: temporaryURL, destinationURL: destinationURL, resumeData: resumeData, result: result.flatMapError(transform), timeline: timeline)
        response._metrics = _metrics
        
        return response
    }
}

protocol Response {
    var _metrics: AnyObject? { get set }
    mutating func add(_ metrics: AnyObject?)
}

extension Response {
    mutating func add(_ metrics: AnyObject?) {
        #if !os(watchOS)
            guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) else { return }
        guard let metrics = metrics as? URLSessionTaskMetrics else { return }
        _metrics = metrics
        #endif
    }
}

// MARK: -这个协议遵守有点意思, 源类中已经定义了一个全局的var _metrics变量,然后分类中再基层一个带有定义_metrics变量的协议 这样居然不会报错

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DefaultDataResponse: Response {
    #if !os(watchOS)
    /// The task metrics containing the request / response statistics.
    public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
    #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DataResponse: Response {
    #if !os(watchOS)
    /// The task metrics containing the request / response statistics.
    public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
    #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DefaultDownloadResponse: Response {
    #if !os(watchOS)
    /// The task metrics containing the request / response statistics.
    public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
    #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DownloadResponse: Response {
    #if !os(watchOS)
    /// The task metrics containing the request / response statistics.
    public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
    #endif
}

