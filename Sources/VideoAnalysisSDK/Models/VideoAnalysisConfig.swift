//
//  VideoAnalysisConfig.swift
//  VideoAnalysisSDK
//
//  视频分析配置

import Foundation

/// 视频分析配置
public struct VideoAnalysisConfig {
    
    // MARK: - 推理配置
    
    /// 推理配置
    public var inferenceConfig: InferenceConfig
    
    // MARK: - 性能参数
    
    /// 跳帧数量（每N帧处理一次）
    public var frameSkip: Int
    
    /// 校准所需帧数
    public var calibrationFrames: Int
    
    // MARK: - 时间范围
    
    /// 开始时间（秒），nil 表示从头开始
    public var startTime: TimeInterval?
    
    /// 结束时间（秒），nil 表示到视频结束
    public var endTime: TimeInterval?
    
    // MARK: - 事件检测参数（可扩展）
    
    /// 事件检测时间窗口（秒）
    public var eventWindow: TimeInterval
    
    /// 事件冷却时间（秒）
    public var eventCooldown: TimeInterval
    
    /// 最小交互时间间隔（秒）
    public var minInteractionInterval: TimeInterval
    
    // MARK: - 空间判定参数（可扩展）
    
    /// 目标区域高度（归一化坐标）
    public var targetZoneHeight: CGFloat
    
    /// 目标区域水平扩展（归一化坐标）
    public var targetZoneHorizontalExpansion: CGFloat
    
    /// 交互判定距离阈值（归一化坐标）
    public var interactionDistanceThreshold: CGFloat
    
    /// 扩展区域系数
    public var expansionFactor: CGFloat
    
    /// 近距离判定阈值（归一化坐标）
    public var closeProximityThreshold: CGFloat
    
    // MARK: - 标签配置
    
    /// 目标标签（篮筐、球门等）
    public var targetLabels: Set<String>
    
    /// 对象标签（篮球、足球等）
    public var objectLabels: Set<String>
    
    // MARK: - 调试参数
    
    /// 调试模式
    public var debugMode: Bool
    
    /// 日志最大数量
    public var maxLogCount: Int
    
    // MARK: - 初始化
    
    public init(
        inferenceConfig: InferenceConfig = .default,
        frameSkip: Int = 3,
        calibrationFrames: Int = 30,
        startTime: TimeInterval? = nil,
        endTime: TimeInterval? = nil,
        eventWindow: TimeInterval = 2.5,
        eventCooldown: TimeInterval = 3.0,
        minInteractionInterval: TimeInterval = 0.05,
        targetZoneHeight: CGFloat = 0.06,
        targetZoneHorizontalExpansion: CGFloat = 0.01,
        interactionDistanceThreshold: CGFloat = 0.20,
        expansionFactor: CGFloat = 0.10,
        closeProximityThreshold: CGFloat = 0.15,
        targetLabels: Set<String> = ["rim", "1", "hoop", "basket", "class_1"],
        objectLabels: Set<String> = ["ball", "0", "basketball", "sport ball", "class_0"],
        debugMode: Bool = false,
        maxLogCount: Int = 1000
    ) {
        self.inferenceConfig = inferenceConfig
        self.frameSkip = frameSkip
        self.calibrationFrames = calibrationFrames
        self.startTime = startTime
        self.endTime = endTime
        self.eventWindow = eventWindow
        self.eventCooldown = eventCooldown
        self.minInteractionInterval = minInteractionInterval
        self.targetZoneHeight = targetZoneHeight
        self.targetZoneHorizontalExpansion = targetZoneHorizontalExpansion
        self.interactionDistanceThreshold = interactionDistanceThreshold
        self.expansionFactor = expansionFactor
        self.closeProximityThreshold = closeProximityThreshold
        self.targetLabels = targetLabels
        self.objectLabels = objectLabels
        self.debugMode = debugMode
        self.maxLogCount = maxLogCount
    }
    
    // MARK: - 预设配置
    
    /// 默认配置（篮球检测）
    public static let `default` = VideoAnalysisConfig()
    
    /// 高性能配置
    public static let performance = VideoAnalysisConfig(
        frameSkip: 5,
        calibrationFrames: 20,
        debugMode: false,
        maxLogCount: 500
    )
    
    /// 高精度配置
    public static let highPrecision = VideoAnalysisConfig(
        inferenceConfig: .highPrecision,
        frameSkip: 2,
        calibrationFrames: 40,
        eventWindow: 2.0,
        eventCooldown: 4.0,
        targetZoneHeight: 0.04,
        interactionDistanceThreshold: 0.15
    )
}

/// 推理配置
public struct InferenceConfig {
    public var confidenceThreshold: Float
    public var nmsThreshold: Float
    public var maxDetections: Int
    public var enableMemoryOptimization: Bool
    public var labelFilter: Set<String>?
    
    public init(
        confidenceThreshold: Float = 0.15,
        nmsThreshold: Float = 0.45,
        maxDetections: Int = 100,
        enableMemoryOptimization: Bool = true,
        labelFilter: Set<String>? = nil
    ) {
        self.confidenceThreshold = confidenceThreshold
        self.nmsThreshold = nmsThreshold
        self.maxDetections = maxDetections
        self.enableMemoryOptimization = enableMemoryOptimization
        self.labelFilter = labelFilter
    }
    
    public static let `default` = InferenceConfig()
    public static let highPrecision = InferenceConfig(confidenceThreshold: 0.5, nmsThreshold: 0.3)
    public static let highRecall = InferenceConfig(confidenceThreshold: 0.1, nmsThreshold: 0.6)
    public static let performance = InferenceConfig(confidenceThreshold: 0.2, maxDetections: 50)
}

/// 视频剪辑配置
public struct VideoClipConfig {
    /// 剪辑前置时间（秒）
    public var leadTime: TimeInterval
    
    /// 剪辑后置时间（秒）
    public var trailTime: TimeInterval
    
    /// 最大并发剪辑任务数
    public var maxConcurrentExports: Int
    
    /// 剪辑超时时间（秒）
    public var exportTimeout: TimeInterval
    
    /// 输出目录（nil 表示使用默认目录）
    public var outputDirectory: URL?
    
    /// 会话名称（用于创建子文件夹）
    public var sessionName: String?
    
    public init(
        leadTime: TimeInterval = 4.0,
        trailTime: TimeInterval = 2.0,
        maxConcurrentExports: Int = 2,
        exportTimeout: TimeInterval = 120,
        outputDirectory: URL? = nil,
        sessionName: String? = nil
    ) {
        self.leadTime = leadTime
        self.trailTime = trailTime
        self.maxConcurrentExports = maxConcurrentExports
        self.exportTimeout = exportTimeout
        self.outputDirectory = outputDirectory
        self.sessionName = sessionName
    }
    
    public static let `default` = VideoClipConfig()
}
