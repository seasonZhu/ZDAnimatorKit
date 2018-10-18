//
//  Placeholder.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/18.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

protocol Placeholder {
    func add(to imageView: ImageView)
    
    func remove(frome imageView: ImageView)
}

// MARK: - 我对这里Self的里面 就是遵守Placeholder协议的本体类的类型
extension Placeholder where Self: Image {
    func add(to imageView: ImageView) { imageView.image = self }
    
    func remove(frome imageView: ImageView) { imageView.image = nil }
}

extension Image: Placeholder {}


extension Placeholder where Self: View {
    
    func add(to imageView: ImageView) {
        imageView.addSubview(self)
    
        ///  系统布局
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: imageView, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: imageView, attribute: .centerY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0),
            ])
    }
    
    func remove(frome imageView: ImageView) {
        self.removeFromSuperview()
    }
}
