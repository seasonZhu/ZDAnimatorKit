//
//  Result.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/22.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

/// 每一个牛逼的框架里都有一个Result success和failure
public enum Result<Value> {
    case success(Value)
    case failure(Error)
    
    
    /// 就算枚举里面带有值 在做一些判断的时候也是可以不写出来的
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    public var isFailure: Bool {
        return !isSuccess
    }
    
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success:
            return "SUCCESS"
        case .failure:
            return "FAILURE"
        }
    }
}

extension Result: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "SUCCESS: \(value)"
        case .failure(let error):
            return "FAILURE: \(error)"
        }
    }
}


/*
 其实这个版块 我是有些看不懂的 主要是throw我不是很了解 边写边学习
 */
extension Result {
    
    /*
     这个两个方法我还是不是很懂
     */
    public init(value: () throws -> Value) {
        do {
            self = try .success(value())
        } catch  {
            self = .failure(error)
        }
    }
    
    public func unwrap() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    public func map<T>(_ transform: (Value) -> T) -> Result<T> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func flatMap<T>(_ transform: (Value) throws -> T) -> Result<T> {
        switch self {
        case .success(let value):
            do {
                return try .success(transform(value))
            }catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func mapError<T: Error>(_ transform: (Error) -> T) -> Result {
        switch self {
        case .failure(let error):
            return .failure(transform(error))
        case .success:
            return self
        }
    }
    
    public func flatMapError<T: Error>(_ transform: (Error) throws -> T) -> Result {
        switch self {
        case .failure(let error):
            do {
                return try .failure(transform(error))
            }catch {
                return .failure(error)
            }
        case .success:
            return self
        }
    }
    
    /*
     if case let .success(value) = self 这个用法其实我也比较疑惑, 另外这是一个链式编程
     */
    @discardableResult
    public func withValue(_ closure: (Value) -> Void) -> Result {
        if case let .success(value) = self {
            closure(value)
        }
        return self
    }
    
    @discardableResult
    public func withError(_ closure: (Error) -> Void) -> Result {
        if case let .failure(error) = self {
            closure(error)
        }
        return self
    }
    
    @discardableResult
    public func ifSuccess(_ closure: () -> Void) -> Result {
        if isSuccess {
            closure()
        }
        return self
    }
    
    @discardableResult
    public func ifFailure(_ closure: () -> Void) -> Result {
        if isFailure {
            closure()
        }
        return self
    }
}
