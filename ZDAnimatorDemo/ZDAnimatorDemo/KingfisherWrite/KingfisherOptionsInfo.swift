//
//  KingfisherOptionsInfo.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

typealias KingfisherOptionsInfo = [KingfisherOptionsInfoItem]
let KingfisherEmptyOptionsInfo = [KingfisherOptionsInfoItem]()
// TODO: - 后写 需要其他的类进行支持
enum KingfisherOptionsInfoItem {
    case targetCache
}
