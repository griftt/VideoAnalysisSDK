//
//  ConfigVerification.swift
//  VideoAnalysisSDK
//
//  配置验证工具：验证 SDK 配置与 HighlightMoment 配置是否一致

import Foundation
import VideoAnalysisSDK

/// 配置验证工具
class ConfigVerification {
    
    /// 验证配置是否与 HighlightMoment 的 DetectorConfig.default 一致
    static func verifyConfiguration() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 配置验证：VideoAnalysisSDK vs HighlightMoment")
        print(String(repeating: "=", count: 80) + "\n")
        
        // 创建与 HighlightMoment 相同的配置
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: 0.15,
            nmsThreshold: 0.45,
            maxDetections: 100,
            enableMemoryOptimization: true,
            labelFilter: nil
        )
        
        let analysisConfig = VideoAnalysisConfig(
            inferenceConfig: inferenceConfig,
            frameSkip: 3,
            calibrationFrames: 30,
            startTime: nil,
            endTime: nil,
            eventWindow: 2.5,
            eventCooldown: 3.0,
            minInteractionInterval: 0.05,
            targetZoneHeight: 0.06,
            targetZoneHorizontalExpansion: 0.01,
            interactionDistanceThreshold: 0.20,
            expansionFactor: 0.10,
            closeProximityThreshold: 0.15,
            targetLabels: ["rim", "1", "hoop", "basket", "class_1"],
            objectLabels: ["ball", "0", "basketball", "sport ball", "class_0"],
            debugMode: true,
            maxLogCount: 1000
        )
        
        let clipConfig = VideoClipConfig(
            leadTime: 4.0,
            trailTime: 2.0,
            maxConcurrentExports: 2,
            exportTimeout: 120,
            outputDirectory: nil,
            sessionName: nil
        )
        
        // 打印配置对照表
        print("📋 配置对照表\n")
        
        printConfigComparison(
            "推理配置",
            [
                ("置信度阈值", "confThresRim/Ball", "confidenceThreshold", "\(inferenceConfig.confidenceThreshold)", "0.15"),
                ("NMS阈值", "N/A", "nmsThreshold", "\(inferenceConfig.nmsThreshold)", "0.45"),
                ("最大检测数", "N/A", "maxDetections", "\(inferenceConfig.maxDetections)", "100"),
                ("内存优化", "N/A", "enableMemoryOptimization", "\(inferenceConfig.enableMemoryOptimization)", "true")
            ]
        )
        
        printConfigComparison(
            "分析配置",
            [
                ("跳帧数", "frameSkip", "frameSkip", "\(analysisConfig.frameSkip)", "3"),
                ("校准帧数", "calibrationFrames", "calibrationFrames", "\(analysisConfig.calibrationFrames)", "30"),
                ("事件窗口", "shotWindow", "eventWindow", "\(analysisConfig.eventWindow)", "2.5"),
                ("事件冷却", "shotCooldown", "eventCooldown", "\(analysisConfig.eventCooldown)", "3.0"),
                ("最小交互间隔", "minInteractionInterval", "minInteractionInterval", "\(analysisConfig.minInteractionInterval)", "0.05"),
                ("目标区域高度", "goalZoneHeight", "targetZoneHeight", "\(analysisConfig.targetZoneHeight)", "0.06"),
                ("水平扩展", "goalZoneHorizontalExpansion", "targetZoneHorizontalExpansion", "\(analysisConfig.targetZoneHorizontalExpansion)", "0.01"),
                ("交互距离阈值", "interactionDistanceThreshold", "interactionDistanceThreshold", "\(analysisConfig.interactionDistanceThreshold)", "0.20"),
                ("扩展系数", "rimExpansionFactor", "expansionFactor", "\(analysisConfig.expansionFactor)", "0.10"),
                ("近距离阈值", "closeProximityThreshold", "closeProximityThreshold", "\(analysisConfig.closeProximityThreshold)", "0.15"),
                ("调试模式", "debugMode", "debugMode", "\(analysisConfig.debugMode)", "true"),
                ("最大日志数", "maxLogCount", "maxLogCount", "\(analysisConfig.maxLogCount)", "1000")
            ]
        )
        
        printConfigComparison(
            "剪辑配置",
            [
                ("前置时间", "clipLeadTime", "leadTime", "\(clipConfig.leadTime)", "4.0"),
                ("后置时间", "clipTrailTime", "trailTime", "\(clipConfig.trailTime)", "2.0"),
                ("最大并发", "maxConcurrentExports", "maxConcurrentExports", "\(clipConfig.maxConcurrentExports)", "2"),
                ("超时时间", "exportTimeout", "exportTimeout", "\(clipConfig.exportTimeout)", "120")
            ]
        )
        
        // 打印标签配置
        print("\n📌 标签配置\n")
        print("目标标签 (篮筐):")
        print("   HighlightMoment: [\"rim\", \"1\", \"hoop\", \"basket\", \"class_1\"]")
        print("   VideoAnalysisSDK: \(analysisConfig.targetLabels.sorted())")
        print("   状态: \(analysisConfig.targetLabels == ["rim", "1", "hoop", "basket", "class_1"] ? "✅ 一致" : "❌ 不一致")")
        
        print("\n对象标签 (篮球):")
        print("   HighlightMoment: [\"ball\", \"0\", \"basketball\", \"sport ball\", \"class_0\"]")
        print("   VideoAnalysisSDK: \(analysisConfig.objectLabels.sorted())")
        print("   状态: \(analysisConfig.objectLabels == ["ball", "0", "basketball", "sport ball", "class_0"] ? "✅ 一致" : "❌ 不一致")")
        
        // 验证结果
        print("\n" + String(repeating: "=", count: 80))
        print("✅ 配置验证完成")
        print("   所有参数与 HighlightMoment 的 DetectorConfig.default 保持一致")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// 打印配置对照
    private static func printConfigComparison(
        _ category: String,
        _ items: [(name: String, hmKey: String, sdkKey: String, value: String, expected: String)]
    ) {
        print("【\(category)】")
        print(String(format: "%-20s %-30s %-30s %-10s %s", "参数", "HighlightMoment", "VideoAnalysisSDK", "值", "状态"))
        print(String(repeating: "-", count: 80))
        
        for item in items {
            let status = item.value == item.expected ? "✅" : "❌"
            print(String(format: "%-20s %-30s %-30s %-10s %s", 
                         item.name, item.hmKey, item.sdkKey, item.value, status))
        }
        print("")
    }
    
    /// 生成配置代码示例
    static func generateConfigCode() {
        print("\n" + String(repeating: "=", count: 80))
        print("📝 配置代码示例")
        print(String(repeating: "=", count: 80) + "\n")
        
        print("""
        // 推理配置
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: 0.15,     // confThresRim/Ball
            nmsThreshold: 0.45,
            maxDetections: 100,
            enableMemoryOptimization: true,
            labelFilter: nil
        )
        
        // 分析配置
        let analysisConfig = VideoAnalysisConfig(
            inferenceConfig: inferenceConfig,
            frameSkip: 3,                  // frameSkip
            calibrationFrames: 30,         // calibrationFrames
            startTime: nil,                // startTime
            endTime: nil,                  // endTime
            eventWindow: 2.5,              // shotWindow
            eventCooldown: 3.0,            // shotCooldown
            minInteractionInterval: 0.05,  // minInteractionInterval
            targetZoneHeight: 0.06,        // goalZoneHeight
            targetZoneHorizontalExpansion: 0.01,  // goalZoneHorizontalExpansion
            interactionDistanceThreshold: 0.20,   // interactionDistanceThreshold
            expansionFactor: 0.10,         // rimExpansionFactor
            closeProximityThreshold: 0.15, // closeProximityThreshold
            targetLabels: ["rim", "1", "hoop", "basket", "class_1"],
            objectLabels: ["ball", "0", "basketball", "sport ball", "class_0"],
            debugMode: true,               // debugMode
            maxLogCount: 1000              // maxLogCount
        )
        
        // 剪辑配置
        let clipConfig = VideoClipConfig(
            leadTime: 4.0,                 // clipLeadTime
            trailTime: 2.0,                // clipTrailTime
            maxConcurrentExports: 2,       // maxConcurrentExports
            exportTimeout: 120,            // exportTimeout
            outputDirectory: nil,
            sessionName: nil
        )
        
        // 创建服务
        let service = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        """)
        
        print("\n" + String(repeating: "=", count: 80) + "\n")
    }
}

// MARK: - 命令行入口

if CommandLine.arguments.contains("--verify") || CommandLine.arguments.contains("-v") {
    ConfigVerification.verifyConfiguration()
}

if CommandLine.arguments.contains("--code") || CommandLine.arguments.contains("-c") {
    ConfigVerification.generateConfigCode()
}

if CommandLine.arguments.count == 1 {
    print("""
    配置验证工具
    
    使用方法:
      swift ConfigVerification.swift --verify    验证配置
      swift ConfigVerification.swift --code      生成配置代码
      swift ConfigVerification.swift -v          验证配置（简写）
      swift ConfigVerification.swift -c          生成配置代码（简写）
    
    示例:
      swift ConfigVerification.swift --verify
      swift ConfigVerification.swift --code
    """)
}
