//
//  ImageProcessor.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/19.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#endif

enum ImageProcessItem {
    case image(Image)
    case data(Data)
}

protocol ImageProcessor {
    var identifier: String { get }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image?
}

typealias ProcessorImp = ((ImageProcessItem, KingfisherOptionsInfo) -> Image?)

extension ImageProcessor {
    func append(another: ImageProcessor) -> ImageProcessor {
        let  newIdentifier = identifier.appending("|>\(another.identifier)")
        return GeneralProcessor(identifier: newIdentifier) { (item, options) -> Image? in
            if let image = self.process(item: item, options: options) {
                return another.process(item: .image(image), options: options)
            }else {
                return nil
            }
        }
    }
}

func == (left: ImageProcessor, right: ImageProcessor) -> Bool {
    return left.identifier == right.identifier
}

func != (left: ImageProcessor, right: ImageProcessor) -> Bool {
    return !(left == right)
}

fileprivate struct GeneralProcessor: ImageProcessor {
    let identifier: String
    let p: ProcessorImp
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return p(item, options)
    }
}


/// 默认的加工器
struct DefaultImageProcessor: ImageProcessor {
    
    static let `default` = DefaultImageProcessor()
    
    let identifier: String = ""
    
    init() {}
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
        case .data(let data):
            return Kingfisher<Image>.image(data: data, scale: options.scaleFactor, preloadAllAnimationData: options.preloadAllAnimationData, onlyFirstFrame:options.onlyFromCache)
        }
    }
}

/// 倒角Option枚举
struct RectCorner: OptionSet {
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let all: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    var cornerIdentifier: String {
        if self == .all {
            return ""
        }
        return "_corner(\(rawValue))"
    }
}

#if !os(macOS)

/// 混合图片加工器
struct BlendImageProcessor: ImageProcessor {
    let identifier: String
    
    let blendMode: CGBlendMode
    
    let alpha: CGFloat
    
    let backgroundColor: Color?
    
    init(blendMode: CGBlendMode, alpha: CGFloat = 1.0, backgroundColor: Color? = nil) {
        self.blendMode = blendMode
        self.alpha = alpha
        self.backgroundColor = backgroundColor
        var identifier = "com.onevcat.Kingfisher.BlendImageProcessor(\(blendMode.rawValue),\(alpha))"
        if let color = backgroundColor {
            identifier.append("_\(color.hex)")
        }
        self.identifier = identifier
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor).kf.image(withBlendModel: blendMode, alpha: alpha, backgroundColor: backgroundColor)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}
#endif

#if os(macOS)
/// Processor for adding an compositing operation to images. Only CG-based images are supported in macOS.
public struct CompositingImageProcessor: ImageProcessor {

    public let identifier: String
    
    public let compositingOperation: NSCompositingOperation
    
    public let alpha: CGFloat
    
    public let backgroundColor: Color?
    
    public init(compositingOperation: NSCompositingOperation, alpha: CGFloat = 1.0, backgroundColor: Color? = nil) {
        self.compositingOperation = compositingOperation
        self.alpha = alpha
        self.backgroundColor = backgroundColor
        var identifier = "com.onevcat.Kingfisher.CompositingImageProcessor(\(compositingOperation.rawValue),\(alpha))"
        if let color = backgroundColor {
            identifier.append("_\(color.hex)")
        }
        self.identifier = identifier
    }
    
    public func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                .kf.image(withCompositingOperation: compositingOperation, alpha: alpha, backgroundColor: backgroundColor)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}
#endif

/// 倒角加工器
struct RoundCornerImageProcessor: ImageProcessor {
    let identifier: String
    
    let cornerRadius: CGFloat
    
    let roundingCorners: RectCorner
    
    let targetSize: CGSize?
    
    let backgroundColor: Color?
    
    init(cornerRadius: CGFloat, targetSize: CGSize? = nil, roundingCorners corners: RectCorner = .all, backgroundColor: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.targetSize = targetSize
        self.roundingCorners = corners
        self.backgroundColor = backgroundColor
        
        self.identifier = {
            var identifier = ""
            
            if let size = targetSize {
                identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor(\(cornerRadius)_\(size)\(corners.cornerIdentifier))"
            } else {
                identifier = "com.onevcat.Kingfisher.RoundCornerImageProcessor(\(cornerRadius)\(corners.cornerIdentifier))"
            }
            if let backgroundColor = backgroundColor {
                identifier += "_\(backgroundColor)"
            }
            
            return identifier
        }()
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let size = targetSize ?? image.kf.size
            return image.kf.scaled(to: options.scaleFactor).kf.image(withRoundRadius: cornerRadius, fit: size, roundingCorners: roundingCorners, backgroundColor: backgroundColor)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// content枚举
enum ContentMode {
    case none
    case aspectFit
    case aspectFill
}

/// 重绘图片size的加工器
struct ResizingImageProcessor: ImageProcessor {
    let identifier: String
    
    let  referenceSize: CGSize
    
    let targetContentMode: ContentMode
    
    init(referenceSize: CGSize, mode: ContentMode = .none) {
        self.referenceSize = referenceSize
        self.targetContentMode = mode
        
        if mode == .none {
            self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(referenceSize))"
        } else {
            self.identifier = "com.onevcat.Kingfisher.ResizingImageProcessor(\(referenceSize), \(mode))"
        }
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor).kf.resize(to: referenceSize, for: targetContentMode)
        default:
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// 毛玻璃加工器
struct BlurImageProcessor: ImageProcessor {
    let identifier: String
    
    let blurRadius: CGFloat
    
    init(blurRadius: CGFloat) {
        self.blurRadius = blurRadius
        self.identifier = "com.onevcat.Kingfisher.BlurImageProcessor(\(blurRadius))"
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            let radius = blurRadius * options.scaleFactor
            return image.kf.scaled(to: options.scaleFactor).kf.blurred(withRadius: radius)
        default:
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// 蒙板加工器
struct OverlayImageProcessor: ImageProcessor {
    let identifier: String
    
    let overlay: Color
    
    let fraction: CGFloat
    
    init(overlay: Color, fraction: CGFloat = 0.5) {
        self.overlay = overlay
        self.fraction = fraction
        self.identifier = "com.onevcat.Kingfisher.OverlayImageProcessor(\(overlay.hex)_\(fraction))"
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor).kf.overlaying(with: overlay, fraction: fraction)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// 着色加工器
struct TintImageProcessor: ImageProcessor {
    let identifier: String
    
    let tint: Color
    
    init(tint: Color) {
        self.tint = tint
        self.identifier = "com.onevcat.Kingfisher.TintImageProcessor(\(tint.hex))"
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor).kf.tinted(with: tint)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// 颜色加工器
struct ColorControlsProcessor: ImageProcessor {
    let identifier: String
    
    let brightness: CGFloat
    
    let contrast: CGFloat
    
    let saturation: CGFloat
    
    let inputEV: CGFloat
    
    init(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.inputEV = inputEV
        self.identifier = "com.onevcat.Kingfisher.ColorControlsProcessor(\(brightness)_\(contrast)_\(saturation)_\(inputEV))"
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.kf.scaled(to: options.scaleFactor)
                .kf.adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// 黑白加工器
struct BlackWhiteProcessor: ImageProcessor {
    let identifier = "com.onevcat.Kingfisher.BlackWhiteProcessor"
    
    init() {}
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        return ColorControlsProcessor(brightness: 0.0, contrast: 1.0, saturation: 0.0, inputEV: 0.7).process(item: item, options: options)
    }
}

/// 切割加工器
struct CroppingImageProcessor: ImageProcessor {
    let identifier: String
    
    let size: CGSize
    
    let anchor: CGPoint
    
    init(size: CGSize, anchor: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        self.size = size
        self.anchor = anchor
        self.identifier = "com.onevcat.Kingfisher.CroppingImageProcessor(\(size)_\(anchor))"
    }
    
    func process(item: ImageProcessItem, options: KingfisherOptionsInfo) -> Image? {
        switch item {
        case .image(let image) :
            return image.kf.scaled(to: options.scaleFactor).kf.crop(to: size, anchorOn: anchor)
        default:
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}


/// 加工器合成计算符
func >>(left: ImageProcessor, right: ImageProcessor) -> ImageProcessor {
    return left.append(another: right)
}

// MARK: - 颜色解析为字符串
extension Color {
    var hex: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        #if os(macOS)
        (usingColorSpace(.sRGB) ?? self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        
        let rInt = Int(r * 255) << 24
        let gInt = Int(g * 255) << 16
        let bInt = Int(b * 255) << 8
        let aInt = Int(a * 255)
        
        let rgba = rInt | gInt | bInt | aInt
        
        return String(format:"#%08x", rgba)
    }
}
