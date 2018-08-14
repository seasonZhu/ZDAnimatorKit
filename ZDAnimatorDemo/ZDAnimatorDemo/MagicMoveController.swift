//
//  MagicMoveController.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/14.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class MagicMoveController: UIViewController {
    
    private lazy var targetImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 88, width: view.bounds.width / 2, height: view.bounds.width / 2))
        imageView.image = UIImage(named: "swift")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()

    override func viewDidLoad() {
        title = "MagicMoveController"
        super.viewDidLoad()
        view.addSubview(targetImageView)
        view.backgroundColor = UIColor.blue
    }
    
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        navigationController?.pushVC(MagicMoveDetailController(), type: .magicMove)
        
        //  present的动画还是失败的 要找原因
        //presentVC(MagicMoveDetailController(), type: .magicMove)
    }
    
    override func animationTransitionTargetView() -> UIView? {
        return targetImageView
    }
    
    deinit {
        print("\(String(describing: self))被销毁了")
    }
}

class MagicMoveDetailController: UIViewController {
    
    private lazy var targetImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: view.center.y - view.bounds.width / 2, width: view.bounds.width, height: view.bounds.width))
        imageView.image = UIImage(named: "swift")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    override func viewDidLoad() {
        title = "MagicMoveDetailController"
        super.viewDidLoad()
        view.addSubview(targetImageView)
        view.backgroundColor = UIColor.lightGray
    }
    
    @objc private func tapAction(_ tap: UITapGestureRecognizer) {
        navigationController?.popViewController(animated: true)
        //dismiss(animated: true, completion: nil)
    }
    
    override func animationTransitionTargetView() -> UIView? {
        return targetImageView
    }

    deinit {
        print("\(String(describing: self))被销毁了")
    }
}

