//
//  AnimatedImageView.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/10/22.
//  Copyright © 2018 season. All rights reserved.
//

import UIKit
import ImageIO

protocol AnimatedImageViewDelegate: class {
    func animatedImageView(_ imageView: AnimatedImageView, didPlayAnimationLoops count: UInt)
    
    func animatedImageViewDidFinishAnimating(_ imageView: AnimatedImageView)
}

extension AnimatedImageViewDelegate {
    func animatedImageView(_ imageView: AnimatedImageView, didPlayAnimationLoops count: UInt) {}
    
    func animatedImageViewDidFinishAnimating(_ imageView: AnimatedImageView) {}
}

class AnimatedImageView: UIImageView {
    class TargetProxy {
        private weak var target: AnimatedImageView?
        
        init(target: AnimatedImageView) {
            self.target = target
        }
        
        @objc func onScreenUpdate() {
            target?.updateFrame()
        }
    }
    
    enum RepeatCount: Equatable {
        case once
        case finite(count: UInt)
        case infinite
        
        static func ==(lhs: RepeatCount, rhs: RepeatCount) -> Bool {
            switch (lhs, rhs) {
            case let (.finite(l), .finite(count: r)):
                return l == r
            case (.once, once), (.infinite, .infinite):
                return true
            case (.once, _), (.infinite, _), (.finite, _):
                return false
            }
        }
    }
    
    var autoPlayAnimatedImage = true
    
    var framePreloadCount = 10
    
    var needsPrescaling = true
    
    var runLoopMode = RunLoop.Mode.commonModes {
        willSet {
            if runLoopMode == newValue {
                return
            }else {
                stopAnimating()
                displayLink.remove(from: .main, forMode: runLoopMode)
                displayLink.add(to: .main, forMode: newValue)
                startAnimating()
            }
        }
    }
    
    var repeatCount = RepeatCount.infinite {
        didSet {
            if oldValue != repeatCount {
                reset()
                setNeedsDisplay()
                layer.setNeedsDisplay()
            }
        }
    }
    
    var delegate: AnimatedImageViewDelegate?
    
    private var animator: Animator?
    
    private var isDisplayLinkInitialized: Bool = false
    
    private lazy var displayLink: CADisplayLink = {
        self.isDisplayLinkInitialized = true
        let displayLink = CADisplayLink(target: TargetProxy(target: self), selector: #selector(TargetProxy.onScreenUpdate))
        displayLink.add(to: .main, forMode: self.runLoopMode)
        displayLink.isPaused = true
        return displayLink
    }()
    
    override var image: Image? {
        didSet {
            if image != oldValue {
                reset()
            }
            setNeedsDisplay()
            layer.setNeedsDisplay()
        }
    }
    
    deinit {
        if isDisplayLinkInitialized {
            displayLink.invalidate()
        }
    }
    
    override var isAnimating: Bool {
        if isDisplayLinkInitialized {
            return !displayLink.isPaused
        }else {
            return super.isAnimating
        }
    }
    
    override func startAnimating() {
        if self.isAnimating {
            return
        }else {
            if animator?.isReachMaxRepeatCount ?? false {
                return
            }
            
            displayLink.isPaused = false
        }
    }
    
    override func stopAnimating() {
        super.stopAnimating()
        if isDisplayLinkInitialized {
            displayLink.isPaused = true
        }
    }
    
    override func display(_ layer: CALayer) {
        if let currentFrame = animator?.currentFrame {
            layer.contents = currentFrame.cgImage
        }else {
            layer.contents = image?.cgImage
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        didMove()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        didMove()
    }
    
    override func shouldPreloadAllAnimation() -> Bool {
        return false
    }
    
    private func reset() {
        animator = nil
        if let imageSource = image?.kf.imageSource?.imageRef {
            animator = Animator(imageSource: imageSource, contentMode: contentMode, size: bounds.size, framePreloadCount: framePreloadCount, repeatCount: repeatCount)
            animator?.delegate = self
            animator?.needsPrescaling = needsPrescaling
            animator?.prepareFramesAsynchronously()
        }
        didMove()
    }
    
    private func didMove() {
        if autoPlayAnimatedImage && animator != nil {
            if let _ = superview, let _ = window {
                startAnimating()
            }else {
                stopAnimating()
            }
        }
    }
    
    private func updateFrame() {
        let duration: CFTimeInterval
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            
            if displayLink.preferredFramesPerSecond == 0 {
                duration = displayLink.duration
            }else {
                duration = 1.0 / Double(displayLink.preferredFramesPerSecond)
            }
            
        }else {
            duration = displayLink.duration
        }
        
        if animator?.updateCurrentFrame(duration: duration) ?? false {
            layer.setNeedsLayout()
            
            if animator?.isReachMaxRepeatCount ?? false {
                stopAnimating()
                delegate?.animatedImageViewDidFinishAnimating(self)
            }
        }
    }
}

extension AnimatedImageView: AnimatorDelegate {
    func animator(_ animator: Animator, didPlayAnimationLoops count: UInt) {
        delegate?.animatedImageView(self, didPlayAnimationLoops: count)
    }
}

/// 每一帧的信息
struct AnimatedFrame {
    var image: Image?
    let duration: TimeInterval
    
    
    /// 这里的none是可选枚举的none值
    static let null = AnimatedFrame(image: .none, duration: 0.0)
}

protocol AnimatorDelegate: class {
    func animator(_ animator: Animator, didPlayAnimationLoops count: UInt)
}

class Animator {
    fileprivate let size: CGSize
    fileprivate let maxFrameCount: Int
    fileprivate let imageSource: CGImageSource
    fileprivate let maxRepeatCount: AnimatedImageView.RepeatCount

    fileprivate var animatedFrames = [AnimatedFrame]()
    fileprivate let maxTimeStep: TimeInterval = 1.0
    fileprivate var frameCount = 0
    fileprivate var currentFrameIndex = 0
    fileprivate var currentFrameIndexInBuffer = 0
    fileprivate var currentPreloadIndex = 0
    fileprivate var timeSinceLastFrameChange: TimeInterval = 0.0
    fileprivate var needsPrescaling = true
    fileprivate var currentRepeatCount: UInt = 0
    fileprivate weak var delegate: AnimatorDelegate?
    
    private var loopCount = 0
    
    var currentFrame: UIImage? {
        return nil
    }
    
    var isReachMaxRepeatCount: Bool {
        switch maxRepeatCount {
        case .once:
            return currentRepeatCount >= 1
        case .finite(let maxCount):
            return currentRepeatCount > maxCount
        case .infinite:
            return false
        }
    }
    
    var contentMode = UIView.ContentMode.scaleToFill
    
    private lazy var preloadQueue: DispatchQueue = {
        return DispatchQueue(label: "com.onevcat.Kingfisher.Animator.preloadQueue")
    }()
    
    init(imageSource source: CGImageSource,
         contentMode mode: UIView.ContentMode,
         size: CGSize,
         framePreloadCount count: Int,
         repeatCount: AnimatedImageView.RepeatCount) {
        self.imageSource = source
        self.contentMode = mode
        self.size = size
        self.maxFrameCount = count
        self.maxRepeatCount = repeatCount
    }
    
    func frame(at index: Int) -> Image? {
        return animatedFrames[safe: index]?.image
    }
    
    func prepareFramesAsynchronously() {
        preloadQueue.async { [weak self] in
           self?.prepareFrames()
        }
    }
    
    func prepareFrames() {
        frameCount = CGImageSourceGetCount(imageSource)
        
        if let properties = CGImageSourceCopyProperties(imageSource, nil),let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary,
            let loopCount = gifInfo[kCGImagePropertyGIFLoopCount as String] as? Int {
            self.loopCount = loopCount
        }
        
        let frameToProcess = min(frameCount, maxFrameCount)
        animatedFrames.reserveCapacity(frameToProcess)
        animatedFrames = (0..<frameToProcess).reduce([]) { $0 + pure(prepareFrame(at: $1))}
        currentPreloadIndex = (frameToProcess + 1) % frameCount - 1
    }
    
    func updateCurrentFrame(duration: CFTimeInterval) -> Bool {
        timeSinceLastFrameChange += min(maxTimeStep, duration)
        
        guard let frameDuration = animatedFrames[safe: currentFrameIndex]?.duration, frameDuration <= timeSinceLastFrameChange else {
            return false
        }
        
        timeSinceLastFrameChange -= frameDuration
        let lastFrameIndex = currentFrameIndexInBuffer
        currentFrameIndexInBuffer += 1
        currentFrameIndexInBuffer = currentFrameIndexInBuffer % animatedFrames.count
        
        if animatedFrames.count < frameCount {
            preloadFrameAsynchronously(at: lastFrameIndex)
        }
        
        currentFrameIndex += 1
        
        if currentFrameIndex == frameCount {
            currentFrameIndex = 0
            currentRepeatCount += 1
            
            delegate?.animator(self, didPlayAnimationLoops: currentRepeatCount)
        }
        
        return true
    }
    
    private func prepareFrame(at index: Int) -> AnimatedFrame {
        guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil) else {
            return AnimatedFrame.null
        }
        
        let defaultGIFFrameDuration = 0.100
        let frameDuration = imageSource.kf.gifProperties(at: index).map { (gifInfo) -> Double in
            let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as Double?
            let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as Double?
            let duration = unclampedDelayTime ?? delayTime ?? 0.0
            return duration > 0.011 ? duration : defaultGIFFrameDuration
        } ?? defaultGIFFrameDuration
        
        let image = Image(cgImage: imageRef)
        let scaledImage: Image?
        
        if needsPrescaling {
            scaledImage = image.kf.resize(to: size, for: contentMode)
        }else {
            scaledImage = image
        }
        
        return AnimatedFrame(image: scaledImage, duration: frameDuration)
    }
    
    private func preloadFrameAsynchronously(at index: Int) {
        preloadQueue.async { [weak self] in
            self?.preloadFrame(at: index)
        }
    }
    
    private func preloadFrame(at index: Int) {
        animatedFrames[index] = prepareFrame(at: currentPreloadIndex)
        currentPreloadIndex += 1
        currentPreloadIndex = currentPreloadIndex % frameCount
    }
}

extension CGImageSource: KingfisherCompatible {}
extension Kingfisher where Base: CGImageSource {
    func gifProperties(at index: Int) -> [String: Double]? {
        let properties = CGImageSourceCopyPropertiesAtIndex(base, index, nil) as Dictionary?
        return properties?[kCGImagePropertyGIFDictionary] as? [String: Double]
    }
}

// MARK: - 安全通过下标取值,这个方法其实可以进行通用
extension Array {
    subscript(safe index: Int) -> Element? {
        print("indices: \(indices), index: \(index)")
        // 这里的~= 感觉是contains函数的意思
        // iOS SDK中是这样的 我猜的没错
        //public static func ~= (pattern: Range<Bound>, value: Bound) -> Bool
        //indices.contains(index)
        let result = indices ~= index
        print("result: \(result)")
        
        return indices ~= index ? self[index] : nil
    }
}


/// 单个元素转为只有一个元素的数组
///
/// - Parameter value: 元素
/// - Returns: 只有一个元素的数组
private func pure<T>(_ value: T) -> [T] {
    return [value]
}
