//
//  VideoClipServiceProtocol.swift
//  VideoAnalysisSDK
//
//  视频剪辑服务协议

import Foundation

/// 视频剪辑服务协议
public protocol VideoClipServiceProtocol: AnyObject {
    
    /// 导出视频剪辑
    /// - Parameters:
    ///   - sourceURL: 源视频URL
    ///   - timestamp: 目标时间点（秒）
    ///   - index: 剪辑索引
    ///   - completion: 完成回调
    func exportClip(
        from sourceURL: URL,
        at timestamp: TimeInterval,
        index: Int,
        completion: @escaping (Result<ClipResult, Error>) -> Void
    )
    
    /// 取消所有导出任务
    func cancelAll()
}
