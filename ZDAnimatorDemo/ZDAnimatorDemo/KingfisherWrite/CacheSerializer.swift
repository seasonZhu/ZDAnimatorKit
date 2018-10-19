//
//  CacheSerializer.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

protocol CacheSerializer {
    func data(with image: Image, original: Data?) -> Data?
    
    func image(with data: Data, options: KingfisherOptionsInfo?) -> Image?
}

struct DefaultCacheSerializer: CacheSerializer {

    public static let `default` = DefaultCacheSerializer()
    private init() {}
    
    func data(with image: Image, original: Data?) -> Data? {
        let imageFormat = original?.kf.imageFormat ?? .unknown
        let data: Data?
        switch imageFormat {
        case .PNG: data = image.kf.pngRepresentation()
        case .JPEG: data = image.kf.jpegRepresentation(compressionQuality: 1.0)
        case .GIF: data = image.kf.gifRepresentation()
        // 连续的kf链式编程
        case .unknown: data = original ?? image.kf.normalized.kf.pngRepresentation()
        }
        
        return data
    }
    
    func image(with data: Data, options: KingfisherOptionsInfo?) -> Image? {
        let options = options ?? KingfisherEmptyOptionsInfo
        return Kingfisher<Image>.image(
            data: data,
            scale: 1.0,
            preloadAllAnimationData: options.preloadAllAnimationData,
            onlyFirstFrame: options.onlyLoadFirstFrame)
    }
}
