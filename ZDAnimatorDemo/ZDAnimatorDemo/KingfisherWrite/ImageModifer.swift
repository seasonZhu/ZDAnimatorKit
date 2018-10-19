//
//  ImageModifer.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

protocol ImageModifier {
    
    func modify(_ image: Image) -> Image
}

extension ImageModifier {
    func modify(_ image: Image?) -> Image? {
        guard let image = image else { return nil }
        
        return modify(image)
    }
}

typealias ModiferImp = ((Image) -> Image)

fileprivate struct GeneralModifier: ImageModifier {
    let identifier: String
    let m: ModiferImp
    
    func modify(_ image: Image) -> Image {
        return m(image)
    }
}

struct DefaultImageModifier: ImageModifier {
    
    static let `default` = DefaultImageModifier()
    
    private init() {}
    
    func modify(_ image: Image) -> Image {
        return image
    }
}

struct AnyImageModifer: ImageModifier {
    
    let block: (Image) -> Image
    
    init(modify: @escaping (Image) -> Image) {
        block = modify
    }
    
    func modify(_ image: Image) -> Image {
        return block(image)
    }
}

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

struct RenderingModeImageModifier: ImageModifier {
    let renderingMode: UIImageRenderingMode
    
    init(renderingMode: UIImageRenderingMode = .automatic) {
        self.renderingMode = renderingMode
    }
    
    func modify(_ image: Image) -> Image {
        return image.withRenderingMode(renderingMode)
    }
}

struct FlipsForRightToLeftLayoutDirectionImageModifier: ImageModifier {
    init() {}
    
    func modify(_ image: Image) -> Image {
        if #available(iOS 9.0, *) {
            return image.imageFlippedForRightToLeftLayoutDirection()
        } else {
            return image
        }
    }
}

struct AlignmentRectInsetsImageModifier: ImageModifier {
    
    let alignmentInsets: UIEdgeInsets
    
    init(alignmentInsets: UIEdgeInsets) {
        self.alignmentInsets = alignmentInsets
    }
    
    func modify(_ image: Image) -> Image {
        return image.withAlignmentRectInsets(alignmentInsets)
    }
}
#endif
