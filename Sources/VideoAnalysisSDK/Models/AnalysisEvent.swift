//
//  AnalysisEvent.swift
//  VideoAnalysisSDK
//
//  分析事件模型

import Foundation
import CoreGraphics

/// 分析事件
public enum AnalysisEvent {
    /// 正在校准
    case calibrating(currentSamples: Int, targetSamples: Int)
    
    /// 校准完成
    case calibrated(box: CGRect)
    
    /// 检测到目标事件（如进球）
    case eventDetected(timestamp: TimeInterval, metadata: [String: Any]?)
    
    /// 自定义事件
    case custom(name: String, data: [String: Any])
}

/// 分析结果
public struct AnalysisResult {
    /// 检测到的事件列表
    public let events: [AnalysisEvent]
    
    /// 处理的总帧数
    public let totalFrames: Int
    
    /// 处理的时长（秒）
    public let duration: TimeInterval
    
    /// 平均FPS
    public var averageFPS: Double {
        duration > 0 ? Double(totalFrames) / duration : 0
    }
    
    public init(events: [AnalysisEvent], totalFrames: Int, duration: TimeInterval) {
        self.events = events
        self.totalFrames = totalFrames
        self.duration = duration
    }
}

/// 剪辑结果
public struct ClipResult {
    /// 剪辑文件URL
    public let url: URL
    
    /// 剪辑索引
    public let index: Int
    
    /// 剪辑时间戳
    public let timestamp: TimeInterval
    
    /// 剪辑时长
    public let duration: TimeInterval
    
    /// 文件大小（字节）
    public let fileSize: Int64
    
    public init(url: URL, index: Int, timestamp: TimeInterval, duration: TimeInterval, fileSize: Int64) {
        self.url = url
        self.index = index
        self.timestamp = timestamp
        self.duration = duration
        self.fileSize = fileSize
    }
}
