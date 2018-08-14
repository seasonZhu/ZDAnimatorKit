//
//  SmoothController.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/14.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class SmoothController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SmoothController"
        view.backgroundColor = UIColor.lightGray
        
        
        let button = UIButton(frame: CGRect(x: 0, y: view.center.y / 2, width: view.bounds.width, height: 22))
        button.setTitle("Present Smooth 到下一个界面", for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
    @objc private func buttonAction(_ button: UIButton) {
        presentVC(SmoothDetailController(), type: .smooth)
    }
    
    deinit {
        print("\(String(describing: self))被销毁了")
    }
}

class SmoothDetailController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SmoothDetailController"
        view.backgroundColor = UIColor.purple
        
        
        let button = UIButton(frame: CGRect(x: 0, y: view.center.y / 2, width: view.bounds.width, height: 22))
        button.setTitle("dismiss 到上个一个界面", for: .normal)
        button.setTitleColor(.black, for: .normal)
        
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        view.addSubview(button)
    }
    
    @objc private func buttonAction(_ button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        print("\(String(describing: self))被销毁了")
    }
}
