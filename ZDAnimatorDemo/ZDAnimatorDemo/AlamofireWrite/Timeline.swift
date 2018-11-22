//
//  Timeline.swift
//  ZDAnimatorDemo
//
//  Created by season on 2018/11/22.
//  Copyright © 2018 season. All rights reserved.
//

import Foundation

public struct Timeline {
    public let requestStartTime: CFAbsoluteTime
    
    public let initialResponseTime: CFAbsoluteTime
    
    public let requestCompletedTime: CFAbsoluteTime
    
    public let serializationCompletedTime: CFAbsoluteTime
    
    public let latency: TimeInterval
    
    public let requestDuration: TimeInterval
    
    public let serializationDuration: TimeInterval
    
    public let totalDuration: TimeInterval
    
    init(requestStartTime: CFAbsoluteTime = 0.0,
         initialResponseTime: CFAbsoluteTime = 0.0,
         requestCompletedTime: CFAbsoluteTime = 0.0,
         serializationCompletedTime: CFAbsoluteTime = 0.0) {
        self.requestStartTime = requestStartTime
        self.initialResponseTime = initialResponseTime
        self.requestCompletedTime = requestCompletedTime
        self.serializationCompletedTime = serializationCompletedTime
        
        self.latency = initialResponseTime - requestStartTime
        self.requestDuration = requestCompletedTime - requestStartTime
        self.serializationDuration = serializationCompletedTime - requestCompletedTime
        self.totalDuration = serializationCompletedTime - requestStartTime
    }
}

extension Timeline: CustomStringConvertible {
    public var description: String {
        let latency = String(format: "%.3f", self.latency)
        let requestDuration = String(format: "%.3f", self.requestDuration)
        let serializationDuration = String(format: "%.3f", self.serializationDuration)
        let totalDuration = String(format: "%.3f", self.totalDuration)
        
        let timings = [
            "\"Latency\": " + latency + " secs",
            "\"Request Duration\": " + requestDuration + " secs",
            "\"Serialization Duration\": " + serializationDuration + " secs",
            "\"Total Duration\": " + totalDuration + " secs"
        ]
        
        return "Timeline: { " + timings.joined(separator: ", ") + " }"
    }
    
    
}

extension Timeline: CustomDebugStringConvertible {
    public var debugDescription: String {
        let requestStartTime = String(format: "%.3f", self.requestStartTime)
        let initialResponseTime = String(format: "%.3f", self.initialResponseTime)
        let requestCompletedTime = String(format: "%.3f", self.requestCompletedTime)
        let serializationCompletedTime = String(format: "%.3f", self.serializationCompletedTime)
        let latency = String(format: "%.3f", self.latency)
        let requestDuration = String(format: "%.3f", self.requestDuration)
        let serializationDuration = String(format: "%.3f", self.serializationDuration)
        let totalDuration = String(format: "%.3f", self.totalDuration)
        
        let timings = [
            "\"Request Start Time\": " + requestStartTime,
            "\"Initial Response Time\": " + initialResponseTime,
            "\"Request Completed Time\": " + requestCompletedTime,
            "\"Serialization Completed Time\": " + serializationCompletedTime,
            "\"Latency\": " + latency + " secs",
            "\"Request Duration\": " + requestDuration + " secs",
            "\"Serialization Duration\": " + serializationDuration + " secs",
            "\"Total Duration\": " + totalDuration + " secs"
        ]
        
        return "Timeline: { " + timings.joined(separator: ", ") + " }"
    }
}
