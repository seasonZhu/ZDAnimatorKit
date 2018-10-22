//
//  Indicator.swift
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

#if os(macOS)
    public typealias IndicatorView = NSView
#else
    public typealias IndicatorView = UIView
#endif

enum IndicatorType {
    case none
    
    case activity
    
    case image(imageData: Data)
    
    case cunstom(indicator: Indicator)
}

protocol Indicator {
    func startAnimatingView()
    func stopAnimatingView()
    
    var viewCenter: CGPoint { get set }
    var view: IndicatorView { get }
}

extension Indicator {
    #if os(macOS)
    var viewCenter: CGPoint {
        get {
            let frame = view.frame
            return CGPoint(x: frame.origin.x + frame.size.width / 2.0, y: frame.origin.y + frame.size.height / 2.0 )
        }
        set {
            let frame = view.frame
            let newFrame = CGRect(x: newValue.x - frame.size.width / 2.0,
                                  y: newValue.y - frame.size.height / 2.0,
                                  width: frame.size.width,
                                  height: frame.size.height)
            view.frame = newFrame
        }
    }
    #else
    var viewCenter: CGPoint {
        get {
            return view.center
        }
        set {
            view.center = newValue
        }
    }
    #endif
}

final class ActivityIndicator: Indicator {
    
    #if os(macOS)
    private let activityIndicatorView: NSProgressIndicator
    #else
    private let activityIndicatorView: UIActivityIndicatorView
    #endif
    private var animatingCount = 0
    
    var view: IndicatorView {
        return activityIndicatorView
    }
    
    func startAnimatingView() {
        animatingCount += 1
        
        if animatingCount == 1 {
            #if os(macOS)
            activityIndicatorView.startAnimation(nil)
            #else
            activityIndicatorView.startAnimating()
            #endif
            activityIndicatorView.isHidden = false
        }
    }
    
    func stopAnimatingView() {
        animatingCount = max(animatingCount - 1, 0)
        if animatingCount == 0 {
            #if os(macOS)
            activityIndicatorView.stopAnimation(nil)
            #else
            activityIndicatorView.stopAnimating()
            #endif
            activityIndicatorView.isHidden = true
        }
    }
    
    init() {
        #if os(macOS)
            activityIndicatorView = NSProgressIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            activityIndicatorView.controlSize = .small
            activityIndicatorView.style = .spinning
        #else
        #if os(tvOS)
            let indicatorStyle = UIActivityIndicatorViewStyle.white
        #else
            let indicatorStyle = UIActivityIndicatorViewStyle.gray
        #endif
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle:indicatorStyle)
            activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
        #endif
    }
}

final class ImageIndicator {
    private let animatedImageIndicatorView: ImageView
    
    var view: IndicatorView {
        return animatedImageIndicatorView
    }
    
    init?(imageData data: Data, processor: ImageProcessor = DefaultImageProcessor.default, options: KingfisherOptionsInfo = KingfisherEmptyOptionsInfo) {
        var options = options
        
        if !options.preloadAllAnimationData {
            options.append(.preloadAllAnimationData)
        }
        
        guard let image = processor.process(item: .data(data), options: options) else {
            return nil
        }
        
        animatedImageIndicatorView = ImageView()
        animatedImageIndicatorView.image = image
        animatedImageIndicatorView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        #if os(macOS)
            // Need for gif to animate on macOS
            self.animatedImageIndicatorView.imageScaling = .scaleNone
            self.animatedImageIndicatorView.canDrawSubviewsIntoLayer = true
        #else
            animatedImageIndicatorView.contentMode = .center
            animatedImageIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        #endif
    }
    
    func startAnimatingView() {
        #if os(macOS)
            animatedImageIndicatorView.animates = true
        #else
            animatedImageIndicatorView.startAnimating()
        #endif
        animatedImageIndicatorView.isHidden = false
    }
    
    func stopAnimatingView() {
        #if os(macOS)
            animatedImageIndicatorView.animates = false
        #else
            animatedImageIndicatorView.stopAnimating()
        #endif
        animatedImageIndicatorView.isHidden = true
    }
}
