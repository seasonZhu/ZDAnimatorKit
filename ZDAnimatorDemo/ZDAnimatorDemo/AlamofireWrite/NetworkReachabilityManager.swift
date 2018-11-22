//
//  NetworkReachabilityManager.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/22.
//  Copyright © 2018 season. All rights reserved.
//

#if !os(watchOS)

import Foundation
import SystemConfiguration

open class NetworkReachabilityManager {
    public enum NetworkReachabilityStatus {
        case unknown
        case notReachable
        case reachable(ConnectionType)
    }
    
    public enum ConnectionType {
        case ethernetOrWifi
        case wwan
    }
    
    public typealias Listener = (NetworkReachabilityStatus) -> Void
    
    open var isReachable: Bool {
        return isReachableOnWWAN || isReachableOnEthernetOrWifi
    }
    
    open var isReachableOnWWAN: Bool {
        return networkReachabilityStatus == .reachable(.wwan)
    }
    
    open var isReachableOnEthernetOrWifi: Bool {
        return networkReachabilityStatus == .reachable(.ethernetOrWifi)
    }
    
    open var networkReachabilityStatus: NetworkReachabilityStatus {
        guard let flags = self.flags else { return .unknown }
        return networkReachabilityStatusForFlags(flags)
    }
    
    open var listenerQueue: DispatchQueue = DispatchQueue.main
    
    open var listener: Listener?
    
    open var flags: SCNetworkReachabilityFlags? {
        var flags = SCNetworkReachabilityFlags()
        
        if SCNetworkReachabilityGetFlags(reachability, &flags) {
            return flags
        }
        
        return nil
    }
    
    private let reachability: SCNetworkReachability
    open var previousFlae: SCNetworkReachabilityFlags
    
    public convenience init?(host: String) {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }
        self.init(reachability: reachability)
    }
    
    public convenience init?() {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        guard let reachability = withUnsafePointer(to: &address, { pointer in
            return pointer.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) {
                return SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else { return nil }
        self.init(reachability: reachability)
    }
    
    private init(reachability: SCNetworkReachability) {
        self.reachability = reachability
        self.previousFlae = SCNetworkReachabilityFlags()
    }
    
    deinit {
        stopListening()
    }
    
    @discardableResult
    open func startListening() -> Bool {
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        let callbackEnabled = SCNetworkReachabilitySetCallback(reachability, { (_, flags, info) in
            
        }, &context)
        
        let queueEnabled = SCNetworkReachabilitySetDispatchQueue(reachability, listenerQueue)
        
        listenerQueue.async {
            
        }
        
        return callbackEnabled && queueEnabled
    }
    
    open func stopListening() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
}


// MARK: - 内部方法
extension NetworkReachabilityManager {
    
    func notifyListener(_ flags: SCNetworkReachabilityFlags) {
        guard previousFlae != flags else {
            return
        }
        previousFlae = flags
        listener?(networkReachabilityStatusForFlags(flags))
    }
    
    func networkReachabilityStatusForFlags(_ flags: SCNetworkReachabilityFlags) -> NetworkReachabilityStatus {
        guard isNetworkReachable(with: flags) else {
            return .notReachable
        }
        
        var networkStatus: NetworkReachabilityStatus = .reachable(.ethernetOrWifi)
        
        #if os(iOS)
        if flags.contains(.isWWAN) {
            networkStatus = .reachable(.wwan)
        }
        #endif
        return networkStatus
    }
    
    func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}

extension NetworkReachabilityManager.NetworkReachabilityStatus: Equatable {}

public func == (lhs: NetworkReachabilityManager.NetworkReachabilityStatus, rhs: NetworkReachabilityManager.NetworkReachabilityStatus) -> Bool {
    switch (lhs, rhs) {
    case (.unknown, .unknown):
        return true
    case (.notReachable, .notReachable):
        return true
    case let (.reachable(lhsConnectionType), .reachable(rhsConnectionType)):
        return lhsConnectionType == rhsConnectionType
    default:
        return false
    }
}

#endif
