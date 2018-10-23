//
//  RequestModifier.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

protocol  ImageDownloadRequestModifier {
    func modified(for request: URLRequest) -> URLRequest?
}

struct NoModifier: ImageDownloadRequestModifier {
    
    /// 结构体也可以使用单例模式
    static let `default` = NoModifier()
    private init() {}
    
    func modified(for request: URLRequest) -> URLRequest? {
        return request
    }
}

struct AnyModifier: ImageDownloadRequestModifier {
    
    let block: (URLRequest) -> URLRequest?

    init(modify: @escaping (URLRequest) -> URLRequest?) {
        block = modify
    }
    
    func modified(for request: URLRequest) -> URLRequest? {
        return block(request)
    }
}
