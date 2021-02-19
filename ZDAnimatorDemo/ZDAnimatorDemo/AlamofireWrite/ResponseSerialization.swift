//
//  ResponseSerialization.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/12/7.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

// MARK: -响应数据序列化协议与结构体

public protocol DataResponseSerializerProtocol {
    associatedtype SerializedObject
    
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error? ) -> Result<SerializedObject> { get }
}

public struct DataResponseSerializer<Value>: DataResponseSerializerProtocol {
    
    public typealias SerializedObject = Value

    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Value>
    
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Value>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: -下载响应序列化协议与结构体

public protocol DownloadResponseSerializerProtocol {
    associatedtype SerializedObject
    
    var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error? ) -> Result<SerializedObject> { get }
}

public struct DownloadResponseSerializer<Value>: DownloadResponseSerializerProtocol {
    
    public typealias SerializedObject = Value
    
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Value>
    
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, URL?, Error?) -> Result<Value>) {
        self.serializeResponse = serializeResponse
    }
}

// MARK: - 请求的Timeline
extension Request {
    var timeline: Timeline {
        let requestStartTime = self.startTime ?? CFAbsoluteTimeGetCurrent()
        let requestCompletedTime = self.endTime ?? CFAbsoluteTimeGetCurrent()
        let initialResponseTime = self.delegate.initialResponseTime ?? requestCompletedTime
        
        return Timeline(
            requestStartTime: requestStartTime,
            initialResponseTime: initialResponseTime,
            requestCompletedTime: requestCompletedTime,
            serializationCompletedTime: CFAbsoluteTimeGetCurrent()
        )
    }
}

// MARK: - Default

extension DataRequeut {
    @discardableResult
    public func response(queue: DispatchQueue? = nil, completionHandler: @escaping (DefaultDataResponse) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var dataResponse = DefaultDataResponse(request: self.request, response: self.response, data: self.delegate.data, error: self.delegate.error, timeline: self.timeline)
                
                dataResponse.add(self.delegate.metrics)
                
                completionHandler(dataResponse)
            }
        }
        return self
    }
    
    @discardableResult
    public func response<T: DataResponseSerializerProtocol>(queue: DispatchQueue? = nil, responseSerializer: T, completionHandler: @escaping (DataResponse<T.SerializedObject>) -> Void) -> Self {
        
        delegate.queue.addOperation {
            let result = responseSerializer.serializeResponse(self.request, self.response, self.delegate.data, self.delegate.error)
            
            var dataResponse = DataResponse<T.SerializedObject>.init(request: self.request, response: self.response, data: self.delegate.data, result: result, timeline: self.timeline)
            
            dataResponse.add(self.delegate.metrics)
            
            (queue ?? DispatchQueue.main).async {
                completionHandler(dataResponse)
            }
        }
        
        return self
    }
}

extension DownloadRequest {
    @discardableResult
    public func response(queue: DispatchQueue? = nil, completionHandler: @escaping (DefaultDownloadResponse) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var downloadResponse = DefaultDownloadResponse(request: self.request, response: self.response, temporaryURL: self.downloadDelegate.temporaryURL, destinationURL: self.downloadDelegate.destinationURL, resumeData: self.downloadDelegate.resumeData, error: self.downloadDelegate.error, timeline: self.timeline)
                
                downloadResponse.add(self.delegate.metrics)
                
                completionHandler(downloadResponse)
            }
        }
        return self
    }
    
    @discardableResult
    public func response<T: DownloadResponseSerializerProtocol>(queue: DispatchQueue? = nil, responseSerializer: T, completionHandler: @escaping (DownloadResponse<T.SerializedObject>) -> Void) -> Self {
        
        delegate.queue.addOperation {
            let result = responseSerializer.serializeResponse(
                self.request,
                self.response,
                self.downloadDelegate.fileURL,
                self.downloadDelegate.error
            )
            
            var downloadResponse = DownloadResponse<T.SerializedObject>(
                request: self.request,
                response: self.response,
                temporaryURL: self.downloadDelegate.temporaryURL,
                destinationURL: self.downloadDelegate.destinationURL,
                resumeData: self.downloadDelegate.resumeData,
                result: result,
                timeline: self.timeline
            )
            
            downloadResponse.add(self.delegate.metrics)
            
            (queue ?? DispatchQueue.main).async {
                completionHandler(downloadResponse)
            }
        }
        
        return self
    }
    
}

// MARK: - 解析为Data

extension Request {
    public static func serializeResponseData(response: HTTPURLResponse?, data: Data?, error: Error?) -> Result<Data> {
        guard error == nil else {
            return .failure(error!)
        }
        
        if let response = response, emptyDataStatusCodes.contains(response.statusCode) {
            return .success(Data())
        }
        
        guard let validData = data else {
            return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
        }
        
        return .success(validData)
    }
}

extension DataRequeut {
    public static func dataResponseSerializer() -> DataResponseSerializer<Data> {
        return DataResponseSerializer(serializeResponse: { (_, response, data, error) in
            return Request.serializeResponseData(response: response, data: data, error: error)
        })
    }
    
    @discardableResult
    public func responseData(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<Data>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequeut.dataResponseSerializer(), completionHandler: completionHandler)
    }
}

extension DownloadRequest {
    public static func dataResponseSerializer() -> DownloadResponseSerializer<Data> {
        return DownloadResponseSerializer { _, response, fileURL, error in
            guard let fileURL = fileURL else {
                return .failure(AFError.responseSerializationFailed(reason: .inputFileNil))
            }
            
            do {
                let data = try Data(contentsOf: fileURL)
                return Request.serializeResponseData(response: response, data: data, error: error)
            } catch {
                return .failure(AFError.responseSerializationFailed(reason: .inputFileReadFailed(at: fileURL)))
            }
        }
    }
    
    @discardableResult
    public func responseData(queue: DispatchQueue? = nil, completionHandler: @escaping (DownloadResponse<Data>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DownloadRequest.dataResponseSerializer(), completionHandler: completionHandler)
    }
}

// MARK: - 解析为String

// MARK: - 解析为JSON

// MARK: - 解析为xml


/// A set of HTTP response status code that do not contain response data.
private let emptyDataStatusCodes: Set<Int> = [204, 205]
