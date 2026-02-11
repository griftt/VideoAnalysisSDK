//
//  VideoAnalysisServiceProtocol.swift
//  VideoAnalysisSDK
//
//  视频分析服务协议

import Foundation

/// 视频分析服务协议
public protocol VideoAnalysisServiceProtocol: AnyObject {
    
    /// 开始分析视频
    /// - Parameters:
    ///   - videoURL: 视频文件URL
    ///   - callbacks: 回调接口
    func startAnalysis(videoURL: URL, callbacks: VideoAnalysisCallbacks)
    
    /// 停止分析
    func stop()
    
    /// 暂停分析
    func pause()
    
    /// 恢复分析
    func resume()
    
    /// 获取运行状态
    var isRunning: Bool { get }
    
    /// 获取暂停状态
    var isPaused: Bool { get }
}

/// 视频分析回调接口
public struct VideoAnalysisCallbacks {
    /// 日志输出
    public var onLog: ((String) -> Void)?
    
    /// 进度更新 (0.0 ~ 1.0)
    public var onProgress: ((Double) -> Void)?
    
    /// 事件检测
    public var onEvent: ((AnalysisEvent) -> Void)?
    
    /// 剪辑创建完成
    public var onClipCreated: ((ClipResult) -> Void)?
    
    /// 分析完成
    public var onCompletion: ((AnalysisResult) -> Void)?
    
    /// 发生错误
    public var onError: ((Error) -> Void)?
    
    public init(
        onLog: ((String) -> Void)? = nil,
        onProgress: ((Double) -> Void)? = nil,
        onEvent: ((AnalysisEvent) -> Void)? = nil,
        onClipCreated: ((ClipResult) -> Void)? = nil,
        onCompletion: ((AnalysisResult) -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.onLog = onLog
        self.onProgress = onProgress
        self.onEvent = onEvent
        self.onClipCreated = onClipCreated
        self.onCompletion = onCompletion
        self.onError = onError
    }
}
