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
    var kf: Kingfisher<Self> {
        return Kingfisher(self)
    }
}

extension Image: KingfisherCompatible {}
#if !os(watchOS)
extension ImageView: KingfisherCompatible { }
extension Button: KingfisherCompatible { }
#else
extension WKInterfaceImage: KingfisherCompatible { }
#endif
