//
//  Validation.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/12/7.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

// MARK: - 这是暂时是写不下去的 还是先写Request类再来写这个
extension Request {
    fileprivate typealias ErrorReason = AFError.ResponseValidationFailureReason
    
    public enum ValidationResult {
        case success
        case failure(Error)
    }
    
    fileprivate struct MIMEType {
        let type: String
        let subtype: String
        
        var isWildCard: Bool {
            return type == "*" && subtype == "*"
        }
        
        init?(_ string: String) {
            let components: [String] = {
                let stripped = string.trimmingCharacters(in: .whitespacesAndNewlines)
                
                /// 这里干了什么 需要研究一下
                #if swift(>=3.2)
                    let split = stripped[..<(stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)]
                #else
                    let split = stripped.substring(to: stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)
                #endif
                
                return split.components(separatedBy: "/")
            }()
            
            if let type = components.first, let subtype = components.last {
                self.type = type
                self.subtype = subtype
            }else {
                return nil
            }
        }
        
        func matches(_ mime: MIMEType) -> Bool {
            /// 匹配模式
            switch (type, subtype) {
            case (mime.type, mime.subtype), (mime.type, "*"), ("*", mime.subtype):
                return true
            default:
                return false
            }
        }
    }
    
    fileprivate var acceptableStatusCodes: [Int] {
        return Array(200..<300)
    }
    
    fileprivate var acceptableContentTypes: [String] {
        if let accept = request?.value(forHTTPHeaderField: "Accept") {
            return accept.components(separatedBy: ",")
        }
        
        return ["*/*"]
    }
    
    /// 验证statusCode
    fileprivate func validate<S: Sequence>(statusCode acceptableStatusCodes: S, response: HTTPURLResponse) -> ValidationResult where S.Iterator.Element == Int {
        if acceptableStatusCodes.contains(response.statusCode) {
            return .success
        }else {
            let reason: ErrorReason = .unacceptableStatusCode(code: response.statusCode)
            return .failure(AFError.responseValidationFailed(reason: reason))
        }
    }
    
    /// 验证Content-Type
    fileprivate func validate<S: Sequence>(contentType acceptableContentTypes: S, response: HTTPURLResponse, data: Data?) -> ValidationResult where S.Iterator.Element == String {
        guard let data = data, data.count > 0 else { return .success }
        
        guard
            let responseContentType = response.mimeType,
            let responseMIMEType = MIMEType(responseContentType)
        else {
            for contentType in acceptableContentTypes {
                if let mimeType = MIMEType(contentType), mimeType.isWildCard {
                    return .success
                }
            }
            
            let error: AFError = {
                let reason: ErrorReason = ErrorReason.missingContentType(acceptableContentTypes: Array(acceptableContentTypes))
                return AFError.responseValidationFailed(reason: reason)
            }()
            
            return .failure(error)
        }
        
        for contentType in acceptableContentTypes {
            if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType) {
                return .success
            }
        }
        
        let error: AFError = {
            let reason: ErrorReason = ErrorReason.unacceptableContentType(acceptableContentTypes: Array(acceptableContentTypes), responseContentType: responseContentType)
            return AFError.responseValidationFailed(reason: reason)
        }()
        
        return .failure(error)
    }
}

extension DataRequeut {
    public typealias Validation = (URLRequest?, HTTPURLResponse, Data?) -> ValidationResult
    
    @discardableResult
    public func validate(_ validation: @escaping Validation) -> Self {
        
        let validationExecution: () -> Void = { [unowned self] in
            if let response = self.response, self.delegate.error == nil, case let .failure(error) = validation(self.request, response, self.delegate.data) {
                self.delegate.error = error
            }
            
        }
        validations.append(validationExecution)
        
        return self
    }
    
    @discardableResult
    public func validate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Element == Int {
        return validate({ [unowned self] (_, response, _) -> Request.ValidationResult in
            return self.validate(statusCode: acceptableStatusCodes, response: response)
        })
    }
    
    @discardableResult
    public func validate<S: Sequence>(contentType acceptableContentTypes: S) -> Self where S.Iterator.Element == String {
        return validate { [unowned self] _, response, data in
            return self.validate(contentType: acceptableContentTypes, response: response, data: data)
        }
    }
    
    @discardableResult
    public func validate() -> Self {
        return validate(statusCode: self.acceptableStatusCodes).validate(contentType: self.acceptableContentTypes)
    }
}

extension DownloadRequest {
    public typealias Validation = (
        _ request: URLRequest?,
        _ response: HTTPURLResponse,
        _ temporaryURL: URL?,
        _ destinationURL: URL?)
        -> ValidationResult
    
    @discardableResult
    public func validate(_ validation: @escaping Validation) -> Self {
        let validationExecution: () -> Void = { [unowned self] in
            let request = self.request
            let temporaryURL = self.downloadDelegate.temporaryURL
            let destinationURL = self.downloadDelegate.destinationURL
            
            if
                let response = self.response,
                self.delegate.error == nil,
                case let .failure(error) = validation(request, response, temporaryURL, destinationURL)
            {
                self.delegate.error = error
            }
        }
        
        validations.append(validationExecution)
        
        return self
    }
    
    @discardableResult
    public func validate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
        return validate { [unowned self] _, response, _, _ in
            return self.validate(statusCode: acceptableStatusCodes, response: response)
        }
    }
    
    @discardableResult
    public func validate<S: Sequence>(contentType acceptableContentTypes: S) -> Self where S.Iterator.Element == String {
        return validate { [unowned self] _, response, _, _ in
            let fileURL = self.downloadDelegate.fileURL
            
            guard let validFileURL = fileURL else {
                return .failure(AFError.responseValidationFailed(reason: .dataFileNil))
            }
            
            do {
                let data = try Data(contentsOf: validFileURL)
                return self.validate(contentType: acceptableContentTypes, response: response, data: data)
            } catch {
                return .failure(AFError.responseValidationFailed(reason: .dataFileReadFailed(at: validFileURL)))
            }
        }
    }
    
    @discardableResult
    public func validate() -> Self {
        return validate(statusCode: self.acceptableStatusCodes).validate(contentType: self.acceptableContentTypes)
    }
}
