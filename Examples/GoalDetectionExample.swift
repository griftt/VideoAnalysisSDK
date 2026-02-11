//
//  GoalDetectionExample.swift
//  VideoAnalysisSDK
//
//  进球检测和自动剪辑示例

import Foundation
import VideoAnalysisSDK
import CoreML

/// 进球检测示例
class GoalDetectionExample {
    
    // MARK: - 完整测试：使用与 HighlightMoment 相同的配置
    
    /// 完整测试：推理 -> 视频分析 -> 剪辑
    /// 使用与 HighlightMoment 项目完全相同的配置参数
    func runCompleteTest() throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🎯 完整测试：使用 HighlightMoment 配置")
        print(String(repeating: "=", count: 80) + "\n")
        
        // 1. 准备视频文件（请替换为实际路径）
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        
        // 2. 配置推理参数（与 HighlightMoment 的 DetectorConfig.default 一致）
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: 0.15,     // confThresRim/Ball
            nmsThreshold: 0.45,
            maxDetections: 100,
            enableMemoryOptimization: true,
            labelFilter: nil               // 不过滤标签
        )
        
        // 3. 配置视频分析参数（与 HighlightMoment 的 DetectorConfig.default 一致）
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
            targetLabels: ["rim", "1", "hoop", "basket", "class_1"],  // 篮筐标签
            objectLabels: ["ball", "0", "basketball", "sport ball", "class_0"],  // 篮球标签
            debugMode: true,               // debugMode
            maxLogCount: 1000              // maxLogCount
        )
        
        // 4. 配置剪辑参数（与 HighlightMoment 的 DetectorConfig.default 一致）
        let clipConfig = VideoClipConfig(
            leadTime: 4.0,                 // clipLeadTime
            trailTime: 2.0,                // clipTrailTime
            maxConcurrentExports: 2,       // maxConcurrentExports
            exportTimeout: 120,            // exportTimeout
            outputDirectory: nil,          // 使用默认目录
            sessionName: "BasketballTest_\(Date().timeIntervalSince1970)"
        )
        
        // 5. 加载ML模型（请替换为实际路径）
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        print("📋 配置信息:")
        print("   • 推理配置:")
        print("     - 置信度阈值: \(inferenceConfig.confidenceThreshold)")
        print("     - NMS阈值: \(inferenceConfig.nmsThreshold)")
        print("     - 最大检测数: \(inferenceConfig.maxDetections)")
        print("   • 分析配置:")
        print("     - 跳帧数: \(analysisConfig.frameSkip)")
        print("     - 校准帧数: \(analysisConfig.calibrationFrames)")
        print("     - 事件窗口: \(analysisConfig.eventWindow)s")
        print("     - 事件冷却: \(analysisConfig.eventCooldown)s")
        print("     - 目标区域高度: \(analysisConfig.targetZoneHeight)")
        print("     - 交互距离阈值: \(analysisConfig.interactionDistanceThreshold)")
        print("   • 剪辑配置:")
        print("     - 前置时间: \(clipConfig.leadTime)s")
        print("     - 后置时间: \(clipConfig.trailTime)s")
        print("     - 最大并发: \(clipConfig.maxConcurrentExports)")
        print("     - 超时时间: \(clipConfig.exportTimeout)s")
        print("")
        
        // 6. 创建分析服务
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        // 7. 配置回调
        var detectedGoals: [(timestamp: TimeInterval, index: Int)] = []
        var createdClips: [ClipResult] = []
        
        let callbacks = VideoAnalysisCallbacks(
            onLog: { log in
                print(log)
            },
            onProgress: { progress in
                if Int(progress * 100) % 10 == 0 {
                    print("⏳ 进度: \(Int(progress * 100))%")
                }
            },
            onEvent: { event in
                switch event {
                case .calibrating(let current, let target):
                    if current == 1 {
                        print("\n🎯 开始校准...")
                    }
                case .calibrated(let box):
                    print("✅ 校准完成")
                    print("   位置: (\(String(format: "%.3f", box.origin.x)), \(String(format: "%.3f", box.origin.y)))")
                    print("   大小: \(String(format: "%.3f", box.size.width)) x \(String(format: "%.3f", box.size.height))")
                case .eventDetected(let timestamp, _):
                    let index = detectedGoals.count + 1
                    detectedGoals.append((timestamp, index))
                    let minutes = Int(timestamp) / 60
                    let seconds = Int(timestamp) % 60
                    print("\n⚽️ 检测到进球 #\(index)")
                    print("   时间: \(String(format: "%.2f", timestamp))s (\(minutes):\(String(format: "%02d", seconds)))")
                case .custom(let name, let metadata):
                    print("📌 自定义事件: \(name)")
                    if let metadata = metadata {
                        print("   详情: \(metadata)")
                    }
                }
            },
            onClipCreated: { clip in
                createdClips.append(clip)
                print("\n🎬 剪辑已创建:")
                print("   文件: \(clip.url.lastPathComponent)")
                print("   时长: \(String(format: "%.2f", clip.duration))秒")
                print("   大小: \(clip.fileSize / 1024)KB")
            },
            onCompletion: { result in
                print("\n" + String(repeating: "=", count: 80))
                print("✅ 测试完成！")
                print(String(repeating: "=", count: 80))
                print("📊 统计信息:")
                print("   • 处理帧数: \(result.totalFrames)")
                print("   • 处理时长: \(String(format: "%.2f", result.duration))秒")
                print("   • 平均FPS: \(String(format: "%.2f", result.averageFPS))")
                print("   • 检测进球: \(detectedGoals.count)个")
                print("   • 创建剪辑: \(createdClips.count)个")
                
                if !detectedGoals.isEmpty {
                    print("\n🎯 进球列表:")
                    for (timestamp, index) in detectedGoals {
                        let minutes = Int(timestamp) / 60
                        let seconds = Int(timestamp) % 60
                        print("   \(index). \(minutes):\(String(format: "%02d", seconds)) (\(String(format: "%.2f", timestamp))s)")
                    }
                }
                
                if !createdClips.isEmpty {
                    print("\n🎬 剪辑列表:")
                    for (index, clip) in createdClips.enumerated() {
                        print("   \(index + 1). \(clip.url.lastPathComponent) (\(String(format: "%.2f", clip.duration))s)")
                    }
                }
                print(String(repeating: "=", count: 80) + "\n")
            },
            onError: { error in
                print("\n❌ 错误: \(error.localizedDescription)")
            }
        )
        
        // 8. 开始分析
        print("🚀 开始分析视频...\n")
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
        
        // 9. 等待完成（在实际应用中，这应该由 RunLoop 或其他机制处理）
        print("💡 提示: 在实际应用中，请使用 RunLoop 或其他机制等待分析完成")
    }
    
    // MARK: - 基础示例：检测并剪辑进球
    
    /// 示例1：完整的进球检测和剪辑流程
    func example1_BasicGoalDetection() throws {
        print("=== 示例1：基础进球检测和剪辑 ===\n")
        
        // 1. 准备视频文件
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        
        // 2. 配置推理参数（针对篮球优化）
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: 0.3,      // 置信度阈值
            nmsThreshold: 0.45,            // NMS阈值
            maxDetections: 50,             // 最大检测数量
            labelFilter: ["basketball", "sports ball", "person"] // 只检测相关物体
        )
        
        // 3. 配置视频分析参数
        let analysisConfig = VideoAnalysisConfig(
            inferenceConfig: inferenceConfig,
            frameSkip: 2,                  // 每2帧处理一次
            calibrationFrames: 30,         // 校准30帧
            eventWindow: 2.5,              // 2.5秒事件窗口
            eventCooldown: 3.0,            // 3秒冷却时间
            debugMode: true                // 开启调试
        )
        
        // 4. 配置剪辑参数
        let clipConfig = VideoClipConfig(
            leadTime: 5.0,                 // 进球前5秒
            trailTime: 3.0,                // 进球后3秒
            sessionName: "BasketballGame_\(Date().timeIntervalSince1970)"
        )
        
        // 5. 加载ML模型
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        // 6. 创建分析服务
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        // 7. 配置回调
        let callbacks = VideoAnalysisCallbacks(
            onLog: { log in
                print("📝 \(log)")
            },
            onProgress: { progress in
                print("⏳ 进度: \(Int(progress * 100))%")
            },
            onEvent: { event in
                if case .eventDetected(let timestamp, let metadata) = event {
                    print("⚽️ 检测到进球！时间: \(timestamp)秒")
                    if let metadata = metadata {
                        print("   详情: \(metadata)")
                    }
                }
            },
            onClipCreated: { clip in
                print("🎬 剪辑已创建:")
                print("   文件: \(clip.url.lastPathComponent)")
                print("   时长: \(clip.duration)秒")
                print("   大小: \(clip.fileSize / 1024)KB")
            },
            onCompletion: { result in
                print("\n✅ 分析完成!")
                print("   处理帧数: \(result.totalFrames)")
                print("   处理时长: \(result.duration)秒")
                print("   平均FPS: \(String(format: "%.1f", result.averageFPS))")
                print("   检测事件: \(result.events.count)个")
            },
            onError: { error in
                print("❌ 错误: \(error.localizedDescription)")
            }
        )
        
        // 8. 开始分析
        print("🚀 开始分析视频...\n")
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
    
    // MARK: - 高级示例：自定义配置
    
    /// 示例2：高精度检测（更慢但更准确）
    func example2_HighPrecisionDetection() throws {
        print("=== 示例2：高精度进球检测 ===\n")
        
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        
        // 使用高精度预设配置
        let analysisConfig = VideoAnalysisConfig.highPrecision
        
        // 自定义剪辑：更长的前后时间
        let clipConfig = VideoClipConfig(
            leadTime: 8.0,     // 进球前8秒
            trailTime: 5.0,    // 进球后5秒
            maxConcurrentExports: 1  // 串行导出，避免资源竞争
        )
        
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        var goalCount = 0
        
        let callbacks = VideoAnalysisCallbacks(
            onEvent: { event in
                if case .eventDetected(let timestamp, _) = event {
                    goalCount += 1
                    print("⚽️ 进球 #\(goalCount) - 时间: \(String(format: "%.2f", timestamp))秒")
                }
            },
            onCompletion: { _ in
                print("\n✅ 检测完成，共发现 \(goalCount) 个进球")
            }
        )
        
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
    
    /// 示例3：高性能检测（更快但可能漏检）
    func example3_HighPerformanceDetection() throws {
        print("=== 示例3：高性能进球检测 ===\n")
        
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        
        // 使用性能预设配置
        let analysisConfig = VideoAnalysisConfig.performance
        
        let clipConfig = VideoClipConfig(
            leadTime: 4.0,
            trailTime: 2.0,
            maxConcurrentExports: 3  // 并行导出，加快速度
        )
        
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        let startTime = Date()
        
        let callbacks = VideoAnalysisCallbacks(
            onCompletion: { result in
                let elapsed = Date().timeIntervalSince(startTime)
                print("\n✅ 快速分析完成!")
                print("   耗时: \(String(format: "%.1f", elapsed))秒")
                print("   处理速度: \(String(format: "%.1f", result.duration / elapsed))x")
            }
        )
        
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
    
    // MARK: - 只检测不剪辑
    
    /// 示例4：只检测进球，不创建剪辑
    func example4_DetectionOnly() throws {
        print("=== 示例4：只检测进球（不剪辑）===\n")
        
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        let analysisConfig = VideoAnalysisConfig.default
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        // 不传入 clipConfig，只进行检测
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig
        )
        
        var goalTimestamps: [TimeInterval] = []
        
        let callbacks = VideoAnalysisCallbacks(
            onEvent: { event in
                if case .eventDetected(let timestamp, _) = event {
                    goalTimestamps.append(timestamp)
                }
            },
            onCompletion: { _ in
                print("\n✅ 检测完成，进球时间点:")
                for (index, timestamp) in goalTimestamps.enumerated() {
                    let minutes = Int(timestamp) / 60
                    let seconds = Int(timestamp) % 60
                    print("   进球 \(index + 1): \(minutes):\(String(format: "%02d", seconds))")
                }
            }
        )
        
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
    
    // MARK: - 分段处理
    
    /// 示例5：只分析视频的特定时间段
    func example5_TimeRangeAnalysis() throws {
        print("=== 示例5：分段分析 ===\n")
        
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        
        // 只分析第2分钟到第5分钟
        var analysisConfig = VideoAnalysisConfig.default
        analysisConfig.startTime = 120.0  // 2分钟
        analysisConfig.endTime = 300.0    // 5分钟
        
        let clipConfig = VideoClipConfig.default
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        let callbacks = VideoAnalysisCallbacks(
            onEvent: { event in
                if case .eventDetected(let timestamp, _) = event {
                    print("⚽️ 在指定时间段内检测到进球: \(timestamp)秒")
                }
            }
        )
        
        print("🚀 只分析 2:00 - 5:00 时间段\n")
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
    
    // MARK: - 暂停和恢复
    
    /// 示例6：控制分析流程（暂停/恢复/停止）
    func example6_ControlAnalysis() throws {
        print("=== 示例6：控制分析流程 ===\n")
        
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        let analysisConfig = VideoAnalysisConfig.default
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig
        )
        
        let callbacks = VideoAnalysisCallbacks(
            onProgress: { progress in
                // 在50%时暂停
                if progress >= 0.5 && !analysisService.isPaused {
                    print("⏸️  暂停分析...")
                    analysisService.pause()
                    
                    // 2秒后恢复
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        print("▶️  恢复分析...")
                        analysisService.resume()
                    }
                }
            },
            onCompletion: { _ in
                print("✅ 分析完成")
            }
        )
        
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
        
        // 可以随时停止
        // analysisService.stop()
    }
    
    // MARK: - 批量处理
    
    /// 示例7：批量处理多个视频
    func example7_BatchProcessing() throws {
        print("=== 示例7：批量处理 ===\n")
        
        let videoURLs = [
            URL(fileURLWithPath: "/path/to/game1.mp4"),
            URL(fileURLWithPath: "/path/to/game2.mp4"),
            URL(fileURLWithPath: "/path/to/game3.mp4")
        ]
        
        let analysisConfig = VideoAnalysisConfig.performance
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        for (index, videoURL) in videoURLs.enumerated() {
            print("\n🎥 处理视频 \(index + 1)/\(videoURLs.count): \(videoURL.lastPathComponent)")
            
            // 为每个视频创建独立的会话
            let clipConfig = VideoClipConfig(
                sessionName: "Game\(index + 1)_\(Date().timeIntervalSince1970)"
            )
            
            let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
                modelURL: modelURL,
                config: analysisConfig,
                clipConfig: clipConfig
            )
            
            var goalCount = 0
            
            let callbacks = VideoAnalysisCallbacks(
                onEvent: { event in
                    if case .eventDetected = event {
                        goalCount += 1
                    }
                },
                onCompletion: { _ in
                    print("   ✅ 完成，检测到 \(goalCount) 个进球")
                }
            )
            
            analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
        }
    }
    
    // MARK: - 自定义输出目录
    
    /// 示例8：指定剪辑输出目录
    func example8_CustomOutputDirectory() throws {
        print("=== 示例8：自定义输出目录 ===\n")
        
        let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
        let analysisConfig = VideoAnalysisConfig.default
        
        // 指定输出目录
        let outputDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/BasketballHighlights")
        
        let clipConfig = VideoClipConfig(
            leadTime: 5.0,
            trailTime: 3.0,
            outputDirectory: outputDir,
            sessionName: "Game_\(Date().formatted(.dateTime.year().month().day()))"
        )
        
        let modelURL = URL(fileURLWithPath: "/path/to/YourModel.mlmodelc")
        
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        let callbacks = VideoAnalysisCallbacks(
            onClipCreated: { clip in
                print("🎬 剪辑保存到: \(clip.url.path)")
            }
        )
        
        print("📁 剪辑将保存到: \(outputDir.path)\n")
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
}

// MARK: - 使用说明

/*
 使用步骤：
 
 1. 准备工作
    - 准备篮球比赛视频文件
    - 准备训练好的 CoreML 模型（.mlmodelc 或 .mlpackage）
    - 确保模型能检测 "basketball" 和 "person" 标签
 
 2. 基础使用
    let example = GoalDetectionExample()
    try example.example1_BasicGoalDetection()
 
 3. 根据需求选择示例
    - 需要高精度？使用 example2
    - 需要快速处理？使用 example3
    - 只需要时间点？使用 example4
    - 批量处理？使用 example7
 
 4. 自定义配置
    - 调整 confidenceThreshold 控制检测灵敏度
    - 调整 frameSkip 平衡速度和精度
    - 调整 leadTime/trailTime 控制剪辑长度
    - 调整 eventCooldown 避免重复检测
 
 5. 输出结果
    - 剪辑文件默认保存在临时目录
    - 可通过 outputDirectory 指定保存位置
    - 文件名格式: highlight_001.mp4, highlight_002.mp4...
 
 注意事项：
 - 确保有足够的磁盘空间存储剪辑
 - 长视频处理可能需要较长时间
 - 建议先用短视频测试配置参数
 - 可以通过 debugMode 查看详细日志
 */
