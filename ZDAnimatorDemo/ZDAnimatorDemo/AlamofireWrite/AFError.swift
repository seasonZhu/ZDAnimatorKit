//
//  AFError.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/22.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

/*
 这个类是所有错误的集合
 在我看来,任何程序在设计之初 定义好各种状态下的枚举是一件非常好的事情
 同时 易于扩展也是设计之中非常重要的
 */

/*
 Error是什么? 和Any一样 是个空协议
 */

public enum AFError: Error {
    
    public enum ParameterEncodingFailureReason {
        case missingURL
        case jsonEncodingFailed(error: Error)
        case propertyListEncodingFailed(error: Error)
    }
    
    public enum MultipartEncodingFailureReason {
        case bodyPartURLInvalid(url: URL)
        case bodyPartFilenameInvalid(url: URL)
        case bodyPartFileNotReachable(at: URL)
        case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
        case bodyPartFileNIsDirectory(at: URL)
        case bodyPartFileSizeNotAvailable(at: URL)
        case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
        case bodyPartInputStreamCreationFailed(for: URL)
        
        case outputStreamCreationFailed(for: URL)
        case outputStreamFileAlreadyExists(at: URL)
        case outputStreamURLInvalid(url: URL)
        case outputStreamWriteFailed(url: URL)
        
        case inputStreamReadFailed(error: Error)
    }
    
    public enum ResponseValidationFailureReason {
        case dataFileNil
        case dataFileReadFailed(at: URL)
        case missingContentType(acceptableContentTypes: [String])
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        case unacceptableStatusCode(code: Int)
    }
    
    public enum ResponseSerializationFailureReason {
        case inputDataNil
        case inputDataNilOrZeroLength
        case inputFileNil
        case inputFileReadFailed(at: URL)
        case stringSerializationFailed(encoding: String.Encoding)
        case jsonSerializtionFailed(error: Error)
        case propertyListSerializtionFailed(error: Error)
    }
    
    case invalidURL(url: URL) // 这个要重新写的
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
    case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
    case responseValidationFailed(reason: ResponseValidationFailureReason)
    case responseSerializationFailed(reason: ResponseSerializationFailureReason)
}

struct AdaptError: Error {
    let error: Error
}

extension Error {
    var underlyingAdaptError: Error? {
        return (self as? AdaptError)?.error
    }
}

extension AFError {
    
    /// 这是匹配模式的一直 如果看不懂这种 请这么看
    public var isInvalidURLError: Bool {
        if case .invalidURL = self {
            return true
        }
        return false
        
        switch self {
        case .invalidURL:
            return true
        default:
            return false
        }
    }
    
    public var isParameterEncodingError: Bool {
        if case .parameterEncodingFailed = self {
            return true
        }
        return false
    }
    
    public var isMultipartEncodingError: Bool {
        if case .multipartEncodingFailed = self {
            return true
        }
        return false
    }
    
    public var isResponseValidationError: Bool {
        if case .responseValidationFailed = self {
            return true
        }
        return false
    }
    
    public var isResponseSerializationError: Bool {
        if case .responseSerializationFailed = self {
            return true
        }
        return false
    }
}
