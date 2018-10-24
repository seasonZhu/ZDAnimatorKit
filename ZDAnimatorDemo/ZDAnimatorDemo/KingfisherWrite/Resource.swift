//
//  Resource.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

protocol Resource {
    var cacheKey: String { get }
    
    var downloadURL: URL { get }
}

/// 这个结构体遵守了Resource协议,同时将var改为了let也没有影响, 但是 协议里是不要用let 可以试试
struct ImageResource: Resource {
    let cacheKey: String
    
    let downloadURL: URL
    
    init(downloadURL: URL, cacheKey: String?) {
        self.downloadURL = downloadURL
        self.cacheKey = cacheKey ?? downloadURL.absoluteString
    }
}

extension URL: Resource {
    var cacheKey: String {
        return absoluteString
    }
    
    var downloadURL: URL {
        return self
    }
}
