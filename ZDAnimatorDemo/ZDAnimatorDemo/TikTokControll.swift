//
//  TikTokControll.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/14.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class TikTokControll: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TikTokControll"
        view.backgroundColor = UIColor.green
        
        
        let button = UIButton(frame: CGRect(x: 0, y: view.center.y / 2, width: view.bounds.width, height: 22))
        button.setTitle("Present tikTok 到下一个界面", for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
    @objc private func buttonAction(_ button: UIButton) {
        presentVC(TikTokDetailController(), type: .tikToComment)
    }

    deinit {
        print("\(String(describing: self))被销毁了")
    }
}

class TikTokDetailController: UIViewController {
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: view.bounds)
        scrollView.contentSize = CGSize(width: view.bounds.width, height: view.bounds.height * 1.5)
        scrollView.delegate = self
        if let animationTransition = self.animationTransition {
            scrollView.panGestureRecognizer.addTarget(animationTransition, action: #selector(animationTransition.handlePanGesture(_:)))
            //addObserver(self, forKeyPath: "scrollView.panGestureRecognizer", options: .new, context: nil)
        }
        
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TikTokDetailController"
        view.backgroundColor = UIColor.gray
        
        view.addSubview(scrollView)
        
        let button = UIButton(frame: CGRect(x: 0, y: view.center.y / 2, width: view.bounds.width, height: 22))
        button.setTitle("dismiss 到上个一个界面", for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        scrollView.addSubview(button)
        
    }
    
    @objc private func buttonAction(_ button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let dict = change, let newValue = dict[NSKeyValueChangeKey.newKey] as? String  else {
            return
        }
        if Int(newValue) == 3 {
            animationTransition?.finish()
        }
    }
    
    deinit {
        print("\(String(describing: self))被销毁了")
    }
}

extension TikTokDetailController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            self.animationTransition?.isOpenPanGesture = true
        }else {
            self.animationTransition?.isOpenPanGesture = false
        }
    }
}

//extension TikTokDetailController {
//    @objc func handlePanGesture(_ panGesture: UIPanGestureRecognizer) {
//        guard let animationTransition = self.animationTransition else {
//            return
//        }
//        
//        var currentDirction = PanDirectionStyle.none
//        
//        guard let window = UIApplication.shared.keyWindow else {
//            return
//        }
//        
//        let translationX = panGesture.translation(in: window).x
//        let translationY = panGesture.translation(in: window).y
//        
//        let moveRangeWidth = UIScreen.main.bounds.width
//        var moveRangeHeight = UIScreen.main.bounds.height
//        
//        if animationTransition.type == .tikToComment {
//            moveRangeHeight = UIScreen.main.bounds.height * 0.618
//        }
//        
//        var rate = panGesture.translation(in: window).x / moveRangeWidth
//        var velocity = panGesture.translation(in: window).y / moveRangeHeight
//        
//        if fabs(translationX) > fabs(translationY) {
//            if translationX > 0 {
//                //  右滑
//                currentDirction = .right
//            }else {
//                //  左滑
//                currentDirction = .left
//            }
//        }else {
//            rate = fabs(panGesture.translation(in: window).y / moveRangeHeight)
//            velocity = fabs(panGesture.velocity(in: window).y)
//            
//            if translationY > 0 {
//                //  下滑
//                currentDirction = .down
//            }else if translationY < 0 {
//                //  上滑
//                currentDirction = .up
//            }
//        }
//        
//        if currentDirction == animationTransition.directionStyle {
//            handleGesture(panGesture, rate: min(1.0, rate), velocity: velocity)
//        }
//        
//    }
//    
//    private func handleGesture(_ gesture: UIGestureRecognizer, rate: CGFloat, velocity: CGFloat) {
//        guard let animationTransition = self.animationTransition else {
//            return
//        }
//        
//        switch gesture.state {
//        case .began:
//            if navigationController != nil {
//                self.navigationController?.popViewController(animated: true)
//            }else {
//                animationTransition.currentViewController?.dismiss(animated: true, completion: nil)
//            }
//        case .changed:
//            animationTransition.update(rate)
//        default:
//            if rate >= kScreenEdgePanMoveScale {
//                animationTransition.finish()
//            }else {
//                if velocity > kScreenEdgePanMoveVelocity {
//                    animationTransition.finish()
//                }else {
//                    animationTransition.cancel()
//                }
//            }
//        }
//    }
//}
