//
//  Kingfisher.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation
import ImageIO

#if os(macOS)
    import AppKit
    public typealias Image = NSImage
    public typealias View = NSView
    public typealias Color = NSColor
    public typealias ImageView = NSImageView
    public typealias Button = NSButton
#else
    import UIKit
    public typealias Image = UIImage
    public typealias Color = UIColor
    #if !os(watchOS)
    public typealias ImageView = UIImageView
    public typealias View = UIView
    public typealias Button = UIButton
    #else
    import WatchKit
    #endif
#endif

/// 这个是一切的基础 以前看总是很神奇 现在看就个就是规定了泛型的类 和我写的泛型装配是一样的 就是说, Kingfisher这个类中 使用了Base这个类
final class Kingfisher<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

protocol KingfisherCompatible {
    associatedtype CompatibleType
    var kf: CompatibleType { get }
}

extension KingfisherCompatible {
    /// 这个地方的Self其实是一个很奇怪的感觉, Self的意思是遵守了KingfisherCompatible这个协议的源类型 而return中的方法是 其实是Kingfisher的init方法
    var kf: Kingfisher<Self> {
        return Kingfisher(self)
    }
}

extension Image: KingfisherCompatible {
    //typealias CompatibleType = Kingfisher<Image> 这个地方其实隐式的做了这样的类型赋值
}

#if !os(watchOS)
    extension ImageView: KingfisherCompatible { }
    extension Button: KingfisherCompatible { }
#else
    extension WKInterfaceImage: KingfisherCompatible { }
#endif
