//
//  Filter.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import CoreImage
import Accelerate

//  滤镜 和函数式编程第二章很像了

private let ciContext = CIContext(options: nil)

typealias Transformer = (CIImage) -> CIImage?


// TODO: - ImageProcessor协议的继承与分类使用


struct Filter {
    let transform: Transformer
    
    init(transform: @escaping Transformer) {
        self.transform = transform
    }
    
    static var tint: (Color) -> Filter = {
        color in
        Filter(transform: {  input in
            let colorFilter = CIFilter(name: "CIConstantColorGenerator")!
            colorFilter.setValue(CIColor(color: color), forKey: kCIInputColorKey)
            let colorImage = colorFilter.outputImage
            let filter = CIFilter(name: "CISourceOverCompositing")!
            filter.setValue(colorImage, forKey: kCIInputImageKey)
            filter.setValue(input, forKey: kCIInputBackgroundImageKey)
            #if swift(>=4.0)
            return filter.outputImage?.cropped(to: input.extent)
            #else
            return filter.outputImage?.cropping(to: input.extent)
            #endif
        })
    }
    
    typealias ColorElement = (CGFloat, CGFloat, CGFloat, CGFloat)
    
    static var colorControl: (ColorElement) -> Filter = { arg -> Filter in
        let (brightness, contrast, saturation, inputEV) = arg
        
        return Filter(transform: { input in
            let paramsColor = [kCIInputBrightnessKey: brightness,
                               kCIInputContrastKey: contrast,
                               kCIInputSaturationKey: saturation]
            
            let paramsExposure = [kCIInputEVKey: inputEV]
            #if swift(>=4.0)
            let blackAndWhite = input.applyingFilter("CIColorControls", parameters: paramsColor)
            return blackAndWhite.applyingFilter("CIExposureAdjust", parameters: paramsExposure)
            #else
            let blackAndWhite = input.applyingFilter("CIColorControls", withInputParameters: paramsColor)
            return blackAndWhite.applyingFilter("CIExposureAdjust", withInputParameters: paramsExposure)
            #endif
        })
    }
}

// MARK: - Deprecated
extension Filter {
    @available(*, deprecated, message: "Use init(transform:) instead.", renamed: "init(transform:)")
    public init(tranform: @escaping Transformer) {
        self.transform = tranform
    }
}

extension Kingfisher where Base: Image {
    func apply(_ filter: Filter) -> Image {
        guard let cgImage = cgImage else {
            assertionFailure("[Kingfisher] Tint image only works for CG-based image.")
            return base
        }
        
        let inputImage = CIImage(cgImage: cgImage)
        guard let outputImage = filter.transform(inputImage) else {
            return base
        }
        
        guard let result = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            assertionFailure("[Kingfisher] Can not make an tint image within context.")
            return base
        }
        
        #if os(macOS)
        return fixedForRetinaPixel(cgImage: result, to: size)
        #else
        return Image(cgImage: result, scale: base.scale, orientation: base.imageOrientation)
        #endif
    }
}
