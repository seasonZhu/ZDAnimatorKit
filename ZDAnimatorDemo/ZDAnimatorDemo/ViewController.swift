//
//  ViewController.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/8/14.
//  Copyright © 2018年 season. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var dataSource = ["smooth 效果", "Mask 效果", "MagicMove 效果", "TikTok 效果"]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 66))
        label.text = "由于Swift的问题 交换方法不能在load方法中调用\n所以实际第一次进行点击是没有效果的\n请先点击Smooth 然后 Present Smooth 再看效果"
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.black
        label.textAlignment = .center
        tableView.tableHeaderView = label
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "自定义转场动画"
        view.addSubview(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.delegate = animationTransition
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            navigationController?.pushVC(SmoothController(), type: .smooth)
        case 1:
            navigationController?.pushVC(MaskController(), type: .none)
        case 2:
            navigationController?.pushVC(MagicMoveController(), type: .none)
        case 3:
            navigationController?.pushVC(TikTokControll(), type: .none)
        default:
            break
        }
    }
}


