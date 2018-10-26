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
    
    private var session: URLSession?
    
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
        let md5 = "www.hao123.com".md5
        let kfMd5 = "www.hao123.com".kf.md5
        if md5 == kfMd5 {
            print("md5取值相等")
        }else {
            print("md5取值不相等")
        }
        
        requestTypeFunction()
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
        tryDownload()
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

extension ViewController {
    func tryDownload() {
        let downloadImageQueue = OperationQueue()
        downloadImageQueue.maxConcurrentOperationCount = 6
        downloadImageQueue.name = "com.season.zhu.downloadImageQueue"
        let url = URL.init(string: "https://dssp.dstsp.com/ow/static/manual/usermanual.pdf")!
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 15.0
        session = URLSession.init(configuration: sessionConfiguration, delegate: self, delegateQueue: downloadImageQueue)
        let downloadTask = session!.downloadTask(with: URLRequest(url: url))
        downloadTask.resume()
        
        if session!.delegateQueue == .main {
            print("在主线程")
        }else {
            print("不在主线程")
        }
    }
}

extension ViewController {
    func kingfisherOptionsInfoMethon() {
        let options: KingfisherOptionsInfo = [.forceRefresh, .preloadAllAnimationData, .downloadPriority(5), .callbackDispatchQueue(DispatchQueue.main)]
        
        let a = options.callbackDispatchQueue
        
        let b = options.downloadPriority
        
        let c =  options.contains { (item) -> Bool in
            let result = item <== .forceRefresh
            return result
        }
        
        let image = UIImage()
        //_ = image.jpegData(compressionQuality: 1) 为什么要封这个方法 我没懂
        
        print(a, b, c)
    }
}

extension ViewController: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location) else {
            return
        }
        
        print("data: \(data.count)")
        
        self.session?.invalidateAndCancel()
        self.session = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("image download currentLength:\(bytesWritten), totalLength:\(totalBytesExpectedToWrite)")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("didCompleteWithError: \(String(describing: error))")
    }
}

struct A: OptionSet {
    
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}


/// 编写了一个网络请求返回的枚举用于DSSP 这里只是思路
///
/// - success: <#success description#>
/// - : <# description#>
enum NetworkRequestType: Int {
    case success = 200,
         created = 201,
         detelet_success = 204,
         not_modified = 304,
         bad_request = 400,
         unathorized = 403,
         not_found = 404,
         service_error = 500
}

extension NetworkRequestType: CustomStringConvertible {
    var description: String {
        switch self {
        case .success:
            return "请求成功"
        case .created:
            return "创建成功"
        case .detelet_success:
            return "删除成功"
        case .not_modified:
            return "数据无更改(返回缓存数据)"
        case .bad_request:
            return "请求错误"
        case .unathorized:
            return "认证失败"
        case .not_found:
            return "找不到资源"
        case .service_error:
            return "服务器错误"
        }
    }
}

extension ViewController {
    func requestTypeFunction() {
        let requestType = NetworkRequestType.not_found
        
        if (300 ... 500).contains(requestType.rawValue) {
            print(requestType)
        }
    }
}
