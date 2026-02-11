import Foundation
import VideoAnalysisSDK
import AVFoundation

/// 示例 1: 基础推理
class Example1_BasicInference {
    func run() {
        do {
            // 创建推理服务
            let service = try VideoAnalysisSDK.createInferenceService(
                modelName: "best",
                config: .default
            )
            
            // 执行推理（需要 CVPixelBuffer）
            // let objects = service.performInference(pixelBuffer: buffer, orientation: .up)
            
            print("✅ 推理服务创建成功")
        } catch {
            print("❌ 错误: \(error)")
        }
    }
}

/// 示例 2: 完整视频分析（自动检测 + 自动剪辑）
class Example2_VideoAnalysis {
    func run(videoURL: URL) {
        do {
            // 1. 配置推理和分析
            let analysisConfig = VideoAnalysisConfig(
                inferenceConfig: InferenceConfig(
                    confidenceThreshold: 0.15,
                    labelFilter: ["basketball", "rim"]
                ),
                frameSkip: 3,
                calibrationFrames: 30,
                debugMode: true
            )
            
            // 2. 配置剪辑
            let clipConfig = VideoClipConfig(
                leadTime: 4.0,      // 进球前4秒
                trailTime: 2.0,     // 进球后2秒
                maxConcurrentExports: 2,
                sessionName: "BasketballHighlights"
            )
            
            // 3. 创建分析服务（带自动剪辑功能）
            let service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelName: "best",
                config: analysisConfig,
                clipConfig: clipConfig  // 传入剪辑配置，启用自动剪辑
            )
            
            // 4. 设置回调
            let callbacks = VideoAnalysisCallbacks(
                onLog: { message in
                    print("📝 \(message)")
                },
                onProgress: { progress in
                    print("📊 进度: \(Int(progress * 100))%")
                },
                onEvent: { event in
                    switch event {
                    case .calibrating(let current, let target):
                        print("� 校准中: \(current)/\(target)")
                    case .calibrated:
                        print("✅ 校准完成")
                    case .eventDetected(let timestamp, _):
                        print("🎯 检测到进球 @ \(String(format: "%.2f", timestamp))s")
                    case .custom(let name, _):
                        print("� 自定义事件: \(name)")
                    }
                },
                onClipCreated: { clipResult in
                    print("✂️ 进球集锦 #\(clipResult.index) 已生成")
                    print("   文件: \(clipResult.url.lastPathComponent)")
                    print("   大小: \(clipResult.fileSize / 1024 / 1024) MB")
                    print("   时长: \(String(format: "%.2f", clipResult.duration))s")
                },
                onCompletion: { result in
                    print("✅ 分析完成")
                    print("   总帧数: \(result.totalFrames)")
                    print("   耗时: \(String(format: "%.2f", result.duration))s")
                    print("   平均FPS: \(String(format: "%.2f", result.averageFPS))")
                },
                onError: { error in
                    print("❌ 错误: \(error.localizedDescription)")
                }
            )
            
            // 5. 开始分析（会自动检测进球并剪辑）
            service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("❌ 错误: \(error)")
        }
    }
}

/// 示例 3: 独立剪辑服务（手动指定时间点）
/// 适用场景：已知进球时间，只需要剪辑，不需要检测
class Example3_VideoClipping {
    func run(videoURL: URL) {
        // 1. 配置剪辑参数
        let config = VideoClipConfig(
            leadTime: 4.0,      // 前置4秒
            trailTime: 2.0,     // 后置2秒
            maxConcurrentExports: 2,
            sessionName: "ManualClips"
        )
        
        // 2. 创建剪辑服务
        let service = VideoAnalysisSDK.createVideoClipService(config: config)
        
        // 3. 手动指定进球时间点（例如从裁判记录或人工标注获得）
        let goalTimestamps = [10.5, 25.3, 42.1, 58.7]
        
        print("开始剪辑 \(goalTimestamps.count) 个进球片段...")
        
        // 4. 批量剪辑
        for (index, timestamp) in goalTimestamps.enumerated() {
            service.exportClip(
                from: videoURL,
                at: timestamp,
                index: index + 1
            ) { result in
                switch result {
                case .success(let clipResult):
                    print("✅ 剪辑 #\(clipResult.index) 完成")
                    print("   时间点: \(String(format: "%.2f", clipResult.timestamp))s")
                    print("   文件: \(clipResult.url.lastPathComponent)")
                    print("   大小: \(clipResult.fileSize / 1024 / 1024) MB")
                case .failure(let error):
                    print("❌ 剪辑 #\(index + 1) 失败: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// 示例 4: 暂停和恢复
class Example4_PauseResume {
    var service: VideoAnalysisServiceProtocol?
    
    func run(videoURL: URL) {
        do {
            service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelName: "best",
                config: .default
            )
            
            let callbacks = VideoAnalysisCallbacks(
                onLog: { print($0) }
            )
            
            service?.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
            // 5秒后暂停
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.service?.pause()
                print("⏸️ 已暂停")
            }
            
            // 10秒后恢复
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.service?.resume()
                print("▶️ 已恢复")
            }
            
        } catch {
            print("❌ 错误: \(error)")
        }
    }
    
    func stop() {
        service?.stop()
    }
}

/// 示例 5: 自定义配置
class Example5_CustomConfig {
    func run(videoURL: URL) {
        do {
            // 自定义推理配置
            let inferenceConfig = InferenceConfig(
                confidenceThreshold: 0.2,
                nmsThreshold: 0.5,
                maxDetections: 50,
                enableMemoryOptimization: true,
                labelFilter: ["basketball", "rim"]
            )
            
            // 自定义分析配置
            let analysisConfig = VideoAnalysisConfig(
                inferenceConfig: inferenceConfig,
                frameSkip: 5,
                calibrationFrames: 40,
                startTime: 10.0,  // 从10秒开始
                endTime: 60.0,    // 到60秒结束
                eventWindow: 3.0,
                eventCooldown: 4.0,
                debugMode: true
            )
            
            // 自定义剪辑配置
            let clipConfig = VideoClipConfig(
                leadTime: 5.0,
                trailTime: 3.0,
                maxConcurrentExports: 1,
                exportTimeout: 180
            )
            
            // 创建服务
            let service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelName: "best",
                config: analysisConfig
            )
            
            let callbacks = VideoAnalysisCallbacks(
                onLog: { print($0) }
            )
            
            service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("❌ 错误: \(error)")
        }
    }
}

/// 示例 6: 预设配置
class Example6_PresetConfigs {
    func runDefault(videoURL: URL) {
        let service = try? VideoAnalysisSDK.createVideoAnalysisService(
            modelName: "best",
            config: .default  // 默认配置
        )
        // ...
    }
    
    func runHighPrecision(videoURL: URL) {
        let service = try? VideoAnalysisSDK.createVideoAnalysisService(
            modelName: "best",
            config: .highPrecision  // 高精度配置
        )
        // ...
    }
    
    func runPerformance(videoURL: URL) {
        let service = try? VideoAnalysisSDK.createVideoAnalysisService(
            modelName: "best",
            config: .performance  // 性能优化配置
        )
        // ...
    }
}
