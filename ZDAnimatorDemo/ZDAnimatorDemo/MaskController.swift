//
//  MaskController.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/14.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class MaskController: UIViewController {
    
    private lazy var targetImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: view.center.x - 25, y: view.center.y, width: 50, height: 50))
        imageView.image = UIImage(named: "twitter")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MaskController"
        view.backgroundColor = UIColor.orange
        
        
        let button = UIButton(frame: CGRect(x: 0, y: view.center.y / 2, width: view.bounds.width, height: 22))
        button.setTitle("Mask 到下一个界面", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        
        view.addSubview(targetImageView)
    }
    
    @objc private func buttonAction(_ button: UIButton) {
        navigationController?.pushVC(MaskDetailController(), type: .mask)
    }

    deinit {
        print("\(String(describing: self))被销毁了")
    }
}

extension MaskController {
    override func animationTransitionTargetView() -> UIView? {
        return targetImageView
    }
}

class MaskDetailController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MaskDetailController"
        view.backgroundColor = UIColor.lightGray
        
        
        let button = UIButton(frame: CGRect(x: 0, y: view.center.y / 2, width: view.bounds.width, height: 22))
        button.setTitle("Pop 到上一个界面", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc private func buttonAction(_ button: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    deinit {
        print("\(String(describing: self))被销毁了")
    }
}
