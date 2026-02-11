//
//  RunCompleteTest.swift
//  VideoAnalysisSDK
//
//  完整测试：使用系统默认配置运行完整流程

import Foundation
import VideoAnalysisSDK
import CoreML

/// 运行完整测试
/// 使用系统默认配置，也支持外部自定义参数
class CompleteTestRunner {
    
    /// 运行完整测试
    /// - Parameters:
    ///   - videoPath: 视频文件路径
    ///   - modelPath: 模型文件路径（支持 .mlmodelc 和 .mlpackage）
    ///   - outputDir: 输出目录（可选）
    ///   - customConfig: 自定义配置（可选，不传则使用系统默认配置）
    static func run(
        videoPath: String,
        modelPath: String,
        outputDir: String? = nil,
        customConfig: VideoAnalysisConfig? = nil
    ) throws {
        print("\n" + String(repeating: "=", count: 80))
        print("🎯 VideoAnalysisSDK 完整测试")
        print("   使用系统默认配置（支持外部自定义）")
        print(String(repeating: "=", count: 80) + "\n")
        
        // 1. 验证文件路径
        let videoURL = URL(fileURLWithPath: videoPath)
        let modelURL = URL(fileURLWithPath: modelPath)
        
        guard FileManager.default.fileExists(atPath: videoPath) else {
            throw VideoAnalysisError.videoLoadFailed("视频文件不存在: \(videoPath)")
        }
        
        guard FileManager.default.fileExists(atPath: modelPath) else {
            throw VideoAnalysisError.modelNotFound(modelPath)
        }
        
        // 检测模型格式
        let modelExtension = modelURL.pathExtension
        let modelFormat = modelExtension == "mlpackage" ? "mlpackage" : "mlmodelc"
        
        print("✅ 文件验证通过")
        print("   📹 视频: \(videoURL.lastPathComponent)")
        print("   🤖 模型: \(modelURL.lastPathComponent) (\(modelFormat))")
        print("")
        
        // 2. 使用配置（优先使用自定义配置，否则使用系统默认配置）
        let analysisConfig = customConfig ?? .default
        
        // 3. 配置剪辑参数
        let outputDirectory = outputDir.map { URL(fileURLWithPath: $0) }
        let clipConfig = VideoClipConfig(
            outputDirectory: outputDirectory,
            sessionName: "Test_\(Date().timeIntervalSince1970)"
        )
        
        // 4. 打印配置信息
        print("📋 配置信息:")
        print("   • 推理配置:")
        print("     - 置信度阈值: \(analysisConfig.inferenceConfig.confidenceThreshold)")
        print("     - NMS阈值: \(analysisConfig.inferenceConfig.nmsThreshold)")
        print("     - 最大检测数: \(analysisConfig.inferenceConfig.maxDetections)")
        print("   • 分析配置:")
        print("     - 跳帧数: \(analysisConfig.frameSkip)")
        print("     - 校准帧数: \(analysisConfig.calibrationFrames)")
        print("     - 时间范围: \(analysisConfig.startTime.map { "\($0)s" } ?? "0s") - \(analysisConfig.endTime.map { "\($0)s" } ?? "结束")")
        print("     - 事件窗口: \(analysisConfig.eventWindow)s")
        print("     - 事件冷却: \(analysisConfig.eventCooldown)s")
        print("     - 目标区域高度: \(analysisConfig.targetZoneHeight)")
        print("     - 交互距离阈值: \(analysisConfig.interactionDistanceThreshold)")
        print("     - 目标标签: \(analysisConfig.targetLabels.sorted().joined(separator: ", "))")
        print("     - 对象标签: \(analysisConfig.objectLabels.sorted().joined(separator: ", "))")
        print("     - 调试模式: \(analysisConfig.debugMode ? "开启" : "关闭")")
        print("   • 剪辑配置:")
        print("     - 前置时间: \(clipConfig.leadTime)s")
        print("     - 后置时间: \(clipConfig.trailTime)s")
        print("     - 最大并发: \(clipConfig.maxConcurrentExports)")
        print("     - 超时时间: \(clipConfig.exportTimeout)s")
        if let dir = outputDirectory {
            print("     - 输出目录: \(dir.path)")
        }
        print("")
        
        // 5. 创建分析服务
        print("🔧 正在创建分析服务...")
        let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        print("✅ 分析服务创建成功\n")
        
        // 6. 配置回调
        var detectedGoals: [(timestamp: TimeInterval, index: Int)] = []
        var createdClips: [ClipResult] = []
        var lastProgressPrint = 0
        var goalCounter = 0
        var isCompleted = false
        let semaphore = DispatchSemaphore(value: 0)
        
        let callbacks = VideoAnalysisCallbacks(
            onLog: { log in
                print(log)
            },
            onProgress: { progress in
                let currentProgress = Int(progress * 100)
                if currentProgress % 10 == 0 && currentProgress != lastProgressPrint {
                    print("⏳ 进度: \(currentProgress)%")
                    lastProgressPrint = currentProgress
                }
            },
            onEvent: { event in
                switch event {
                case .calibrating(let current, let target):
                    if current == 1 {
                        print("\n🎯 开始校准...")
                    }
                    if current % 10 == 0 {
                        let progress = Double(current) / Double(target) * 100
                        print("   🟢 校准进度: \(current)/\(target) (\(String(format: "%.0f", progress))%)")
                    }
                case .calibrated(let box):
                    print("\n✅ 校准完成！")
                    print("   • 位置: (\(String(format: "%.3f", box.origin.x)), \(String(format: "%.3f", box.origin.y)))")
                    print("   • 大小: \(String(format: "%.3f", box.size.width)) x \(String(format: "%.3f", box.size.height))")
                    print("\n🔍 开始事件检测...\n")
                case .eventDetected(let timestamp, _):
                    goalCounter += 1
                    let index = detectedGoals.count + 1
                    detectedGoals.append((timestamp, index))
                    let minutes = Int(timestamp) / 60
                    let seconds = Int(timestamp) % 60
                    print("\n" + String(repeating: "=", count: 60))
                    print("⚽️ 🎉 检测到进球 #\(goalCounter)")
                    print(String(repeating: "=", count: 60))
                    print("   • 时间: \(String(format: "%.2f", timestamp))s (\(minutes):\(String(format: "%02d", seconds)))")
                    print("   • 总进球数: \(goalCounter)")
                    print("   ✂️  正在准备剪辑...")
                case .custom(let name, let metadata):
                    print("📌 自定义事件: \(name)")
                    print("   详情: \(metadata)")
                }
            },
            onClipCreated: { clip in
                createdClips.append(clip)
                print("\n🎬 剪辑已创建:")
                print("   • 进球编号: #\(createdClips.count)")
                print("   • 文件: \(clip.url.lastPathComponent)")
                print("   • 路径: \(clip.url.path)")
                print("   • 时长: \(String(format: "%.2f", clip.duration))秒")
                print("   • 大小: \(String(format: "%.2f", Double(clip.fileSize) / 1024 / 1024))MB")
                print("   ✅ 剪辑完成！")
                print(String(repeating: "=", count: 60) + "\n")
            },
            onCompletion: { result in
                guard !isCompleted else { return }
                isCompleted = true
                
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
                        print("   \(index + 1). \(clip.url.lastPathComponent)")
                        print("       路径: \(clip.url.path)")
                        print("       时长: \(String(format: "%.2f", clip.duration))s")
                    }
                }
                print(String(repeating: "=", count: 80) + "\n")
                
                // 通知主线程完成
                semaphore.signal()
            },
            onError: { error in
                guard !isCompleted else { return }
                isCompleted = true
                
                print("\n❌ 错误: \(error.localizedDescription)")
                
                // 通知主线程完成（即使出错）
                semaphore.signal()
            }
        )
        
        // 7. 开始分析
        print("🚀 开始分析视频...\n")
        print("💡 提示: 分析正在后台运行，请等待完成...\n")
        
        analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
        
        // 8. 等待完成（使用 RunLoop 保持主线程活跃，同时等待信号量）
        print("⏳ 等待分析完成...\n")
        
        // 在后台线程等待信号量，避免阻塞主线程
        DispatchQueue.global().async {
            semaphore.wait()
            // 完成后停止 RunLoop
            CFRunLoopStop(CFRunLoopGetMain())
        }
        
        // 运行 RunLoop 以处理回调
        RunLoop.main.run()
        
        print("\n🎉 程序执行完毕，即将退出...\n")
    }
}

// MARK: - 命令行入口

/// 命令行使用示例:
/// 
/// 1. 使用默认配置:
///    swift run CompleteTest <视频路径> <模型路径> [输出目录]
/// 
/// 2. 使用自定义配置（在代码中修改）:
///    编辑 main() 函数，创建自定义 VideoAnalysisConfig

@main
struct CompleteTestMain {
    static func main() {
        if CommandLine.arguments.count >= 3 {
            let videoPath = CommandLine.arguments[1]
            let modelPath = CommandLine.arguments[2]
            let outputDir = CommandLine.arguments.count >= 4 ? CommandLine.arguments[3] : nil
            
            // 方式1: 使用系统默认配置
            let config: VideoAnalysisConfig? = nil
            
            // 方式2: 使用自定义配置（示例）
            // var config = VideoAnalysisConfig.default
            // config.debugMode = true
            // config.startTime = 400
            
            // 方式3: 完全自定义配置（示例）
            // let config = VideoAnalysisConfig(
            //     inferenceConfig: .default,
            //     frameSkip: 3,
            //     calibrationFrames: 30,
            //     startTime: 400,
            //     debugMode: true
            // )
            
            do {
                try CompleteTestRunner.run(
                    videoPath: videoPath,
                    modelPath: modelPath,
                    outputDir: outputDir,
                    customConfig: config
                )
            } catch {
                print("❌ 测试失败: \(error.localizedDescription)")
                exit(1)
            }
        } else {
            print("""
            使用方法:
            swift run CompleteTest <视频路径> <模型路径> [输出目录]
            
            模型格式支持:
            - .mlmodelc (编译后的模型)
            - .mlpackage (模型包)
            
            示例:
            swift run CompleteTest ~/Videos/basketball.mp4 ~/Models/yolo.mlmodelc
            swift run CompleteTest ~/Videos/basketball.mp4 ~/Models/yolo.mlpackage ~/Desktop/Clips
            
            配置说明:
            - 默认使用系统预设的最佳配置
            - 如需自定义配置，请编辑 main() 函数中的 config 变量
            """)
            exit(1)
        }
    }
}
