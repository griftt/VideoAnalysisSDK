//
//  VideoAnalysisError.swift
//  VideoAnalysisSDK
//
//  错误定义

import Foundation

/// 视频分析错误
public enum VideoAnalysisError: LocalizedError {
    case modelNotFound(String)
    case modelLoadFailed(String)
    case videoLoadFailed(String)
    case videoTrackNotFound
    case readerCreationFailed(String)
    case exportFailed(String)
    case invalidTimeRange
    case cancelled
    case timeout
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "模型未找到: \(name)"
        case .modelLoadFailed(let reason):
            return "模型加载失败: \(reason)"
        case .videoLoadFailed(let reason):
            return "视频加载失败: \(reason)"
        case .videoTrackNotFound:
            return "视频轨道未找到"
        case .readerCreationFailed(let reason):
            return "读取器创建失败: \(reason)"
        case .exportFailed(let reason):
            return "导出失败: \(reason)"
        case .invalidTimeRange:
            return "无效的时间范围"
        case .cancelled:
            return "操作已取消"
        case .timeout:
            return "操作超时"
        case .unknown(let reason):
            return "未知错误: \(reason)"
        }
    }
}
