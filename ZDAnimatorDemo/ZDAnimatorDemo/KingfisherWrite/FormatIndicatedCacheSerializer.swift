//
//  FormatIndicatedCacheSerializer.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

struct FormatIndicatedCacheSerializer: CacheSerializer {
    
    /// 这个地方调用的是结构体的默认构造方法
    static let png = FormatIndicatedCacheSerializer(imageFormat: .PNG)
    static let jpeg = FormatIndicatedCacheSerializer(imageFormat: .JPEG)
    static let gif = FormatIndicatedCacheSerializer(imageFormat: .GIF)
    
    /// The indicated image format.
    private let imageFormat: ImageFormat
    
    func data(with image: Image, original: Data?) -> Data? {
        
        func imageData(withFormat imageFormat: ImageFormat) -> Data? {
            switch imageFormat {
            case .PNG: return image.kf.pngRepresentation()
            case .JPEG: return image.kf.jpegRepresentation(compressionQuality: 1.0)
            case .GIF: return image.kf.gifRepresentation()
            case .unknown: return nil
            }
        }
        
        if let data = imageData(withFormat: imageFormat) {
            return data
        }
        
        let originalFormat = original?.kf.imageFormat ?? .unknown
        
        if originalFormat != imageFormat, let data = imageData(withFormat: originalFormat) {
            return data
        }
        
        return original ?? image.kf.normalized.kf.pngRepresentation()
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
