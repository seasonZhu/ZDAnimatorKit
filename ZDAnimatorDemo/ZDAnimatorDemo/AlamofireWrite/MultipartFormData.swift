//
//  MultipartFormData.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/26.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
import MobileCoreServices
#elseif os(macOS)
import CoreServices
#endif

public typealias HTTPHeaders = [String: String]

/*
 这段翻译出自Alamofire的关于表单数据化的英文:
 针对HTTP or HTTPS的请求体的multipart/form-data上传模式.目前有两种对其序列化的方式.
 第一种方式是直接在内存进行序列化,这种方式很有效率,但是当数据过大的时候,会导致内存问题.
 第二种方式专为数据过大而设计,将数据适当的通过boundary分割后,序列化,然后生成单个文件并写入到沙盒中.第二种方式适用于大数据例如视频,因此你的App可能因为序列化的时候内存暴增而挂掉
 */
/// 表单化工具类
open class MultipartFormData {
    struct EncodingCharacters {
        static let crlf = "\r\n"
    }
    
    /// 分界线生成器
    struct BoundaryGenerator {
        enum BoundaryType {
            case initial, encapsulated, final
        }
        
        static func radomBoundary() -> String {
            return String(format: "alamofire.boundary.%08x.%08x", arc4random(), arc4random())
        }
        
        static func boundaryData(forBoundaryType boundaryType: BoundaryType, boundary: String) -> Data {
            let boundaryText: String
            switch boundaryType {
            case .initial:
                boundaryText = "--\(boundary)\(EncodingCharacters.crlf)"
            case .encapsulated:
                boundaryText = "\(EncodingCharacters.crlf)--\(boundary)\(EncodingCharacters.crlf)"
            case .final:
                boundaryText = "\(EncodingCharacters.crlf)--\(boundary)--\(EncodingCharacters.crlf)"
            }
            return boundaryText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        }
    }
    
    class BodyPart {
        let headers: HTTPHeaders
        let bodyStream: InputStream
        let bodyContentLength: UInt64
        var hasInitialBoundary = false
        var hasFinalBoundary = false
        
        init(headers: HTTPHeaders, bodyStream: InputStream, bodyContentLength: UInt64) {
            self.headers = headers
            self.bodyStream = bodyStream
            self.bodyContentLength = bodyContentLength
        }
    }
    
    open lazy var contentType: String = "multipart/form-data; boundary=\(self.boundary)"
    
    public var contentLength: UInt64 { return bodyParts.reduce(0) { $0 + $1.bodyContentLength } }
    
    public let boundary: String
    
    private var bodyParts: [BodyPart]
    private var bodyPartError: AFError?
    private let streamBufferSize: Int
    
    public init() {
        self.boundary = BoundaryGenerator.radomBoundary()
        self.bodyParts = []
        
        self.streamBufferSize = 1024
    }
    
    ///  这三个函数写起来有意义吗 写一个不行吗
    public func append(_ data: Data, withName name: String) {
        let headers = contentHeaders(withName: name)
        let stream = InputStream(data: data)
        let length = UInt64(data.count)
        
        append(stream, withLength: length, headers: headers)
    }
    
    public func append(_ data: Data, withName name: String, mimeType: String) {
        let headers = contentHeaders(withName: name, mimeType: mimeType)
        let stream = InputStream(data: data)
        let length = UInt64(data.count)
        
        append(stream, withLength: length, headers: headers)
    }
    
    public func append(_ data: Data, withName name: String, fileName: String, mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        let stream = InputStream(data: data)
        let length = UInt64(data.count)
        
        append(stream, withLength: length, headers: headers)
    }
    
    public func append(_ fileURL: URL, withName name: String) {
        let fileName = fileURL.lastPathComponent
        let pathExtension = fileURL.pathExtension
        
        if !fileName.isEmpty && !pathExtension.isEmpty {
            let mime = mimeType(forPathExtension: pathExtension)
            append(fileURL, withName: name, fileName: fileName, mimeType: mime)
        }else {
            setBodyPartError(withReason: .bodyPartFilenameInvalid(url: fileURL))
        }
    }
    
    /// 通过fileURL创建一个body 并添加其到表单对象中
    ///
    /// - Parameters:
    ///   - fileURL: 文件路径
    ///   - name: Content-Disposition的名称
    ///   - fileName: 文件名称
    ///   - mimeType: 文件类型
    public func append(_ fileURL: URL, withName name: String, fileName: String, mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        
        ///  检查是不是fileURL
        guard fileURL.isFileURL else {
            setBodyPartError(withReason: .bodyPartURLInvalid(url: fileURL))
            return
        }
        
        ///  检查fileURL是否可以到达?
        do {
            let isReachable = try fileURL.checkPromisedItemIsReachable()
            guard isReachable else {
                setBodyPartError(withReason: .bodyPartFileNotReachable(at: fileURL))
                return
            }
        } catch {
            setBodyPartError(withReason: .bodyPartFileNotReachableWithError(atURL: fileURL, error: error))
            return
        }
        
        /// 检查fileURL是不是一个目录
        var isDirectory: ObjCBool = false
        let path = fileURL.path
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && !isDirectory.boolValue else {
            setBodyPartError(withReason: .bodyPartFileIsDirectory(at: fileURL))
            return
        }
        
        /// 检查文件是否可以被取出?
        let bodyContentLength: UInt64
        
        do {
            guard let fileSize = try FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber else {
                setBodyPartError(withReason: .bodyPartFileSizeNotAvailable(at: fileURL))
                return
            }
            bodyContentLength = fileSize.uint64Value
        } catch {
            setBodyPartError(withReason: .bodyPartFileSizeQueryFailedWithError(forURL: fileURL, error: error))
            return
        }
        
        /// 检查一个inputStream可以通过fileURL进行创建
        guard let inputStream = InputStream(url: fileURL) else {
            setBodyPartError(withReason: .bodyPartInputStreamCreationFailed(for: fileURL))
            return
        }
        
        append(inputStream, withLength: bodyContentLength, headers: headers)
    }
    
    public func append(_ stream: InputStream, withLength length: UInt64, name: String, fileName: String, mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        append(stream, withLength: length, headers: headers)
    }
    
    public func append(_ stream: InputStream, withLength length: UInt64, headers: HTTPHeaders) {
        let bodyPart = BodyPart(headers: headers, bodyStream: stream, bodyContentLength: length)
        bodyParts.append(bodyPart)
    }
    
    //MARK:- 序列化数据
    public func encode() throws -> Data {
        if let bodyPartError = bodyPartError {
            throw bodyPartError
        }
        
        var encoded = Data()
        
        bodyParts.first?.hasInitialBoundary = true
        bodyParts.last?.hasFinalBoundary = true
        
        for bodyPart in bodyParts {
            let encodedData = try encode(bodyPart)
            encoded.append(encodedData)
        }
        
        return encoded
    }
    
    //MARK:- 写入序列化数据到文件目录下
    public func writeEncodedData(to fileURL: URL) throws {
        if let bodyPartError = bodyPartError {
            throw bodyPartError
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            throw AFError.multipartEncodingFailed(reason: .outputStreamFileAlreadyExists(at: fileURL))
        }else if !fileURL.isFileURL {
            throw AFError.multipartEncodingFailed(reason: .outputStreamURLInvalid(url: fileURL))
        }
        
        guard let outputStream = OutputStream(url: fileURL, append: false) else {
            throw AFError.multipartEncodingFailed(reason: .outputStreamCreationFailed(for: fileURL))
        }
        
        outputStream.open()
        defer { outputStream.close() }
        
        self.bodyParts.first?.hasInitialBoundary = true
        self.bodyParts.last?.hasFinalBoundary = true
        
        for bodyPart in self.bodyParts {
            try write(bodyPart, to: outputStream)
        }
    }
    
    //MARK:- 将Http请求体 Body 的序列化
    private func encode(_ bodyPart: BodyPart) throws -> Data {
        var encoded = Data()
        
        let initialData = bodyPart.hasInitialBoundary ? initalBoundaryData() : encapsulatedBoundaryData()
        encoded.append(initialData)
        
        let headerData = encodeHeaders(for: bodyPart)
        encoded.append(headerData)
        
        let bodyStreamData = try encode(bodyPart)
        encoded.append(bodyStreamData)
        
        if bodyPart.hasFinalBoundary {
            encoded.append(finalBoundaryData())
        }
        return encoded
    }
    
    private func encodeHeaders(for bodyPart: BodyPart) -> Data {
        var headerText = ""
        
        for (key, value) in bodyPart.headers {
            headerText += "\(key): \(value)\(EncodingCharacters.crlf)"
        }
        headerText += EncodingCharacters.crlf
        
        return headerText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
    }
    
    private func encodeBodyStream(for bodyPart: BodyPart) throws -> Data {
        let inputStream = bodyPart.bodyStream
        inputStream.open()
        defer { inputStream.close() }
        
        var encoded = Data()
        
        while inputStream.hasBytesAvailable {
            var buffer = [UInt8].init(repeating: 0, count: streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)
            
            if let error = inputStream.streamError {
                throw AFError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: error))
            }
            
            if bytesRead > 0 {
                encoded.append(buffer, count: bytesRead)
            }else {
                break
            }
        }
        
        return encoded
    }
    
    //MARK:- 将Http请求体 Body 写为outputstream
    private func write(_ bodyPart: BodyPart, to outputStream: OutputStream) throws {
        try writeInitialBoundaryData(for: bodyPart, to: outputStream)
        try writeHeaderData(for: bodyPart, to: outputStream)
        try writeBodyStream(for: bodyPart, to: outputStream)
        try writeFinalBoundaryData(for: bodyPart, to: outputStream)
    }
    
    private func writeInitialBoundaryData(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        let initialData = bodyPart.hasInitialBoundary ? initalBoundaryData() : encapsulatedBoundaryData()
        return try write(initialData, to: outputStream)
    }
    
    private func writeHeaderData(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        let headerData = encodeHeaders(for: bodyPart)
        return try write(headerData, to: outputStream)
    }
    
    private func writeBodyStream(for bodyPart: BodyPart, to outputSteam: OutputStream) throws {
        let inputStream = bodyPart.bodyStream
        
        inputStream.open()
        defer { inputStream.close() }
        
        while inputStream.hasBytesAvailable  {
            var buffer = [UInt8].init(repeating: 0, count: streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)
            
            if let streamError = inputStream.streamError {
                throw AFError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: streamError))
            }
            
            if bytesRead > 0 {
                if buffer.count != bytesRead {
                    buffer = Array(buffer[0 ..< bytesRead])
                }
                
                try write(&buffer, to: outputSteam)
            }else {
                break
            }
        }
    }
    
    private func writeFinalBoundaryData(for bodyPart: BodyPart, to outputStream: OutputStream) throws {
        if bodyPart.hasFinalBoundary {
            return try write(finalBoundaryData(), to: outputStream)
        }
    }
    
    //MARK:- 数据 buffer 转 Output Strream
    private func write(_ data: Data, to outputStream: OutputStream) throws {
        var buffer = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &buffer, count: data.count)
        
        return try write(&buffer, to: outputStream)
    }
    
    private func write(_ buffer: inout [UInt8], to outputStream: OutputStream) throws {
        var bytesToWrite = buffer.count
        
        while bytesToWrite > 0, outputStream.hasSpaceAvailable {
            let bytesWritten = outputStream.write(buffer, maxLength: bytesToWrite)
            
            if let error = outputStream.streamError {
                throw AFError.multipartEncodingFailed(reason: .outputStreamWriteFailed(error: error))
            }
            
            bytesToWrite -= bytesToWrite
            
            if bytesToWrite > 0 {
                buffer = Array(buffer[bytesWritten ..< buffer.count])
            }
        }
    }
    
    //MARK:- Mime Type 这里面的函数是什么意思呢
    private func mimeType(forPathExtension pathExtenstion: String) -> String {
        if let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtenstion as CFString, nil)?.takeRetainedValue(), let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        
        return "application/octet-stream"
    }
    
    
    //MARK:- contentHeaders的装配赋值
    private func contentHeaders(withName name: String, fileName: String? = nil, mimeType: String? = nil) -> [String: String] {
        var disposition = "form-data; name=\"\(name)\""
        if let fileName = fileName {
            disposition += "; filename=\"\(fileName)\""
        }
        
        var headers = ["Content-Disposition": disposition]
        if let mimeType = mimeType {
            headers["Content-Type"] = mimeType
        }
        
        return headers
    }
    
    //MARK:- 分割线序列化
    private func initalBoundaryData() -> Data {
        return BoundaryGenerator.boundaryData(forBoundaryType: .initial, boundary: boundary)
    }
    
    private func encapsulatedBoundaryData() -> Data {
        return BoundaryGenerator.boundaryData(forBoundaryType: .encapsulated, boundary: boundary)
    }
    
    private func finalBoundaryData() -> Data {
        return BoundaryGenerator.boundaryData(forBoundaryType: .final, boundary: boundary)
    }
    
    //MARK:- set错误
    private func setBodyPartError(withReason reason: AFError.MultipartEncodingFailureReason) {
        guard bodyPartError == nil else {
            return
        }
        bodyPartError = AFError.multipartEncodingFailed(reason: reason)
    }
}
