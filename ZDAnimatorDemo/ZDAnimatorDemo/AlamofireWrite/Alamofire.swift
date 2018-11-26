//
//  Alamofire.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/23.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

/*
 URL可变性协议
 这个协议的用处有两个: 一个是将String/URL/URLComponents类都正确的返回url,二个是将这三个类统一为一个类
 */
public protocol URLConvertible {
    func asURL() throws -> URL
}

extension String: URLConvertible {
    /*
     这个我们来聊一下 throws -> URL 这个写法 这是我的理解
     如果正常就 -> URL 如果不正常 throws
     
     另外 对于有throws的函数
     都需要这么写
     do {
        try? "haha".asURL()
     }catch let error {
        print(error)
     }
     
     这里我们的error会抛出AFError.invalidURL 需要注意的是throw 后面的类型 都必须遵守Error协议,比如下面注释的 我throw了一个字符串 但是必须这样
     extension String: Error {}
     才能正确编译过
     
     你其实可以这么理解throws 函数后面隐式的添加了 throws -> Error 这样样子
     
     其实这样会发现 一个函数 可以返回两种完全不同的类型 -> URL 是一种 或者throw 一种 😝
     
     */
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else {
            throw AFError.invalidURL(url: self)
            //  throw "转失败了吧"
        }
        return url
    }
}

extension String: Error {}

extension URL: URLConvertible {
    public func asURL() throws -> URL {
        return self
    }
}

extension URLComponents: URLConvertible {
    public func asURL() throws -> URL {
        guard let url = url else { throw AFError.invalidURL(url: self) }
        return url
    }
}

public protocol URLRequsetConvertible {
    func asURLRequest() throws -> URLRequest
}

extension URLRequsetConvertible {
    public var urlRequest: URLRequest? {
        return try? asURLRequest()
    }
}
