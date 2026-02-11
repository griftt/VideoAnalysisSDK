import XCTest
import AVFoundation
import CoreML
@testable import VideoAnalysisSDK

final class VideoAnalysisSDKTests: XCTestCase {
    
    // MARK: - BoundingBox Tests
    
    func testBoundingBoxCenter() {
        let box = BoundingBox(x: 0.0, y: 0.0, width: 0.4, height: 0.6)
        XCTAssertEqual(box.centerX, 0.2)
        XCTAssertEqual(box.centerY, 0.3)
    }
    
    func testBoundingBoxIoU() {
        let box1 = BoundingBox(x: 0.0, y: 0.0, width: 0.5, height: 0.5)
        let box2 = BoundingBox(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        
        let iou = box1.iou(with: box2)
        XCTAssertGreaterThan(iou, 0)
        XCTAssertLessThan(iou, 1)
    }
    
    func testBoundingBoxDistance() {
        let box1 = BoundingBox(x: 0.0, y: 0.0, width: 0.2, height: 0.2)
        let box2 = BoundingBox(x: 0.3, y: 0.4, width: 0.2, height: 0.2)
        
        let distance = box1.distance(to: box2)
        XCTAssertGreaterThan(distance, 0)
    }
    
    // MARK: - Config Tests
    
    func testInferenceConfigDefault() {
        let config = InferenceConfig.default
        XCTAssertEqual(config.confidenceThreshold, 0.15)
        XCTAssertEqual(config.nmsThreshold, 0.45)
        XCTAssertEqual(config.maxDetections, 100)
        XCTAssertTrue(config.enableMemoryOptimization)
    }
    
    func testVideoAnalysisConfigDefault() {
        let config = VideoAnalysisConfig.default
        XCTAssertEqual(config.frameSkip, 3)
        XCTAssertEqual(config.calibrationFrames, 30)
        XCTAssertNil(config.startTime)
        XCTAssertNil(config.endTime)
    }
    
    func testVideoClipConfigDefault() {
        let config = VideoClipConfig.default
        XCTAssertEqual(config.leadTime, 4.0)
        XCTAssertEqual(config.trailTime, 2.0)
        XCTAssertEqual(config.maxConcurrentExports, 2)
    }
    
    // MARK: - DetectedObject Tests
    
    func testDetectedObjectCodable() throws {
        let object = DetectedObject(
            label: "basketball",
            confidence: 0.95,
            boundingBox: BoundingBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            timestamp: 1.5
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DetectedObject.self, from: data)
        
        XCTAssertEqual(decoded.label, object.label)
        XCTAssertEqual(decoded.confidence, object.confidence)
        XCTAssertEqual(decoded.boundingBox.x, object.boundingBox.x)
        XCTAssertEqual(decoded.timestamp, object.timestamp)
    }
    
    // MARK: - AnalysisResult Tests
    
    func testAnalysisResultAverageFPS() {
        let result = AnalysisResult(
            events: [],
            totalFrames: 300,
            duration: 10.0
        )
        
        XCTAssertEqual(result.averageFPS, 30.0)
    }
    
    // MARK: - ClipResult Tests
    
    func testClipResult() {
        let url = URL(fileURLWithPath: "/tmp/clip.mp4")
        let result = ClipResult(
            url: url,
            index: 1,
            timestamp: 10.5,
            duration: 6.0,
            fileSize: 1024000
        )
        
        XCTAssertEqual(result.index, 1)
        XCTAssertEqual(result.timestamp, 10.5)
        XCTAssertEqual(result.duration, 6.0)
        XCTAssertEqual(result.fileSize, 1024000)
    }
    
    // MARK: - 进球检测和剪辑测试
    
    /// 测试进球检测和自动剪辑功能
    func testGoalDetectionAndClipping() throws {
        // 创建测试视频URL（实际使用时需要提供真实的视频文件）
        let testVideoURL = createTestVideoURL()
        
        // 跳过测试如果没有测试视频
        guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
            throw XCTSkip("测试视频不存在，跳过测试。请将测试视频放在: \(testVideoURL.path)")
        }
        
        // 配置推理参数（针对篮球检测优化）
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: 0.15,      // 置信度阈值
            nmsThreshold: 0.45,            // NMS阈值
            maxDetections: 50,             // 最大检测数量
            enableMemoryOptimization: true,
            labelFilter: nil               // 不过滤，查看所有检测结果
        )
        
        // 配置视频分析参数
        let analysisConfig = VideoAnalysisConfig(
            inferenceConfig: inferenceConfig,
            frameSkip: 2,                  // 每2帧处理一次（提高精度）
            calibrationFrames: 30,         // 校准帧数
            startTime: nil,                // 从头开始（改为 nil，处理整个视频）
            endTime: 120.0,                 // 只处理前60秒（1分钟）用于测试
            eventWindow: 2.5,              // 事件检测窗口2.5秒
            eventCooldown: 3.0,            // 事件冷却时间3秒
            targetZoneHeight: 0.06,        // 篮筐区域高度
            interactionDistanceThreshold: 0.20, // 交互距离阈值
            debugMode: true,               // 开启调试模式
            maxLogCount: 1000
        )
        
        // 配置视频剪辑参数
        let clipConfig = VideoClipConfig(
            leadTime: 4.0,                 // 进球前5秒
            trailTime: 2.0,                // 进球后3秒
            maxConcurrentExports: 2,       // 最大并发剪辑数
            exportTimeout: 120,            // 剪辑超时时间
            outputDirectory: createTestOutputDirectory(), // 输出目录
            sessionName: "GoalDetectionTest" // 会话名称
        )
        
        // 创建模拟的ML模型（实际使用时需要加载真实模型）
        let mockModel = try createMockMLModel()
        
        // 创建视频分析服务（带剪辑功能）
        let analysisService = VideoAnalysisSDK.createVideoAnalysisService(
            model: mockModel,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        // 创建期望对象
        let completionExpectation = expectation(description: "分析完成")
        let eventExpectation = expectation(description: "检测到进球事件")
        let clipExpectation = expectation(description: "创建剪辑")
        
        // 允许检测到多个事件
        eventExpectation.assertForOverFulfill = false
        clipExpectation.assertForOverFulfill = false
        
        // 记录检测结果
        var detectedEvents: [AnalysisEvent] = []
        var createdClips: [ClipResult] = []
        var analysisLogs: [String] = []
        
        // 配置回调
        var lastProgress = 0.0
        var detectionCount = 0
        let callbacks = VideoAnalysisCallbacks(
            onLog: { log in
                print("📝 日志: \(log)")
                analysisLogs.append(log)
            },
            onProgress: { progress in
                let progressPercent = Int(progress * 100)
                // 只在进度变化时打印
                if progress - lastProgress >= 0.01 {
                    print("⏳ 进度: \(progressPercent)% [\(String(format: "%.2f", progress))]")
                    lastProgress = progress
                }
                
                // 在关键进度点打印详细信息
                if progressPercent == 90 || progressPercent == 95 || progressPercent == 99 {
                    print("   📊 当前进度: \(progressPercent)%")
                    print("   🔍 已检测事件数: \(detectedEvents.count)")
                    print("   � 已创建剪辑数: \(createdClips.count)")
                }
            },
            onEvent: { event in
                detectionCount += 1
                print("\n🎯 事件 #\(detectionCount): \(event)")
                detectedEvents.append(event)
                
                // 检查是否是进球事件
                if case .eventDetected(let timestamp, let metadata) = event {
                    print("⚽️ 检测到进球！时间: \(timestamp)秒")
                    if let metadata = metadata {
                        print("   元数据: \(metadata)")
                    }
                    eventExpectation.fulfill()
                } else if case .calibrating(let current, let target) = event {
                    if current % 10 == 0 {
                        print("   校准进度: \(current)/\(target)")
                    }
                } else if case .calibrated(let box) = event {
                    print("   ✅ 校准完成，目标区域: \(box)")
                }
            },
            onClipCreated: { clipResult in
                print("🎬 剪辑创建成功:")
                print("   索引: \(clipResult.index)")
                print("   时间戳: \(clipResult.timestamp)秒")
                print("   时长: \(clipResult.duration)秒")
                print("   文件大小: \(clipResult.fileSize / 1024)KB")
                print("   路径: \(clipResult.url.path)")
                
                createdClips.append(clipResult)
                clipExpectation.fulfill()
            },
            onCompletion: { result in
                print("\n" + String(repeating: "=", count: 50))
                print("✅ 分析完成:")
                print("   总帧数: \(result.totalFrames)")
                print("   处理时长: \(String(format: "%.2f", result.duration))秒")
                print("   平均FPS: \(String(format: "%.2f", result.averageFPS))")
                print("   检测到的事件数: \(result.events.count)")
                print(String(repeating: "=", count: 50))
                
                completionExpectation.fulfill()
            },
            onError: { error in
                print("❌ 错误: \(error.localizedDescription)")
                // 即使失败也要满足期望，避免测试超时
                completionExpectation.fulfill()
                XCTFail("分析失败: \(error)")
            }
        )
        
        // 开始分析
        print("\n" + String(repeating: "=", count: 50))
        print("🚀 开始分析视频: \(testVideoURL.lastPathComponent)")
        print("⏱️  开始时间: \(Date())")
        print("📊 配置信息:")
        print("   - 帧跳过: \(analysisConfig.frameSkip)")
        print("   - 时间范围: \(analysisConfig.startTime ?? 0)s - \(analysisConfig.endTime.map { "\($0)s" } ?? "结束")")
        print("   - 剪辑配置: 前\(clipConfig.leadTime)s + 后\(clipConfig.trailTime)s")
        print(String(repeating: "=", count: 50) + "\n")
        
        analysisService.startAnalysis(videoURL: testVideoURL, callbacks: callbacks)
        
        // 等待完成（超时时间根据视频长度调整）
        wait(for: [completionExpectation], timeout: 300)
        
        // 验证结果
        XCTAssertFalse(detectedEvents.isEmpty, "应该检测到至少一个事件")
        XCTAssertFalse(analysisLogs.isEmpty, "应该有日志输出")
        
        // 如果检测到进球事件，应该创建剪辑
        let goalEvents = detectedEvents.filter {
            if case .eventDetected = $0 { return true }
            return false
        }
        
        if !goalEvents.isEmpty {
            XCTAssertFalse(createdClips.isEmpty, "检测到进球后应该创建剪辑")
            
            // 验证剪辑文件
            for clip in createdClips {
                XCTAssertTrue(FileManager.default.fileExists(atPath: clip.url.path),
                             "剪辑文件应该存在: \(clip.url.path)")
                XCTAssertGreaterThan(clip.fileSize, 0, "剪辑文件大小应该大于0")
                XCTAssertGreaterThan(clip.duration, 0, "剪辑时长应该大于0")
            }
        }
        
        // 打印总结
        print("\n📊 测试总结:")
        print("   检测到的事件: \(detectedEvents.count)")
        print("   进球事件: \(goalEvents.count)")
        print("   创建的剪辑: \(createdClips.count)")
        print("   日志条数: \(analysisLogs.count)")
    }
    
    /// 测试只检测不剪辑
    func testGoalDetectionOnly() throws {
        let testVideoURL = createTestVideoURL()
        
        guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
            throw XCTSkip("测试视频不存在")
        }
        
        // 使用高精度配置
        let analysisConfig = VideoAnalysisConfig.highPrecision
        let mockModel = try createMockMLModel()
        
        // 创建不带剪辑功能的分析服务
        let analysisService = VideoAnalysisSDK.createVideoAnalysisService(
            model: mockModel,
            config: analysisConfig
        )
        
        let completionExpectation = expectation(description: "分析完成")
        var detectedGoals: [(timestamp: TimeInterval, metadata: [String: Any]?)] = []
        
        let callbacks = VideoAnalysisCallbacks(
            onEvent: { event in
                if case .eventDetected(let timestamp, let metadata) = event {
                    detectedGoals.append((timestamp, metadata))
                    print("⚽️ 进球时间: \(timestamp)秒")
                }
            },
            onCompletion: { result in
                print("✅ 检测完成，共发现 \(detectedGoals.count) 个进球")
                completionExpectation.fulfill()
            },
            onError: { error in
                XCTFail("检测失败: \(error)")
            }
        )
        
        analysisService.startAnalysis(videoURL: testVideoURL, callbacks: callbacks)
        wait(for: [completionExpectation], timeout: 300)
        
        // 验证检测到的进球
        for (index, goal) in detectedGoals.enumerated() {
            print("进球 \(index + 1): \(goal.timestamp)秒")
            XCTAssertGreaterThan(goal.timestamp, 0, "进球时间应该大于0")
        }
    }
    
    /// 测试自定义剪辑配置
    func testCustomClipConfiguration() throws {
        let testVideoURL = createTestVideoURL()
        
        guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
            throw XCTSkip("测试视频不存在")
        }
        
        // 自定义剪辑配置：更长的前后时间
        let clipConfig = VideoClipConfig(
            leadTime: 10.0,    // 进球前10秒
            trailTime: 5.0,    // 进球后5秒
            maxConcurrentExports: 3,
            outputDirectory: createTestOutputDirectory(),
            sessionName: "CustomClipTest"
        )
        
        let analysisConfig = VideoAnalysisConfig.default
        let mockModel = try createMockMLModel()
        
        let analysisService = VideoAnalysisSDK.createVideoAnalysisService(
            model: mockModel,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        let completionExpectation = expectation(description: "分析完成")
        var clips: [ClipResult] = []
        
        let callbacks = VideoAnalysisCallbacks(
            onClipCreated: { clip in
                clips.append(clip)
                // 验证剪辑时长应该约为 leadTime + trailTime
                let expectedDuration = clipConfig.leadTime + clipConfig.trailTime
                XCTAssertEqual(clip.duration, expectedDuration, accuracy: 1.0,
                              "剪辑时长应该约为 \(expectedDuration)秒")
            },
            onCompletion: { _ in
                completionExpectation.fulfill()
            },
            onError: { error in
                XCTFail("分析失败: \(error)")
            }
        )
        
        analysisService.startAnalysis(videoURL: testVideoURL, callbacks: callbacks)
        wait(for: [completionExpectation], timeout: 300)
        
        print("创建了 \(clips.count) 个自定义时长的剪辑")
    }
    
    // MARK: - 辅助方法
    
    /// 创建测试视频URL
    private func createTestVideoURL() -> URL {
        // 方法1: 使用项目中的测试视频
        #if SWIFT_PACKAGE
        print("🔍 尝试从 Bundle.module 加载视频...")
        
        // 尝试小写扩展名
        if let bundleURL = Bundle.module.url(forResource: "test_basketball", withExtension: "mp4") {
            print("✅ 找到视频: \(bundleURL.path)")
            return bundleURL
        }
        
        // 尝试大写扩展名
        if let bundleURL = Bundle.module.url(forResource: "test_basketball", withExtension: "MP4") {
            print("✅ 找到视频: \(bundleURL.path)")
            return bundleURL
        }
        
        // 尝试在 Resources 子目录中查找
        if let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("Resources") {
            print("📂 检查 Resources 子目录: \(resourcesURL.path)")
            
            let mp4URL = resourcesURL.appendingPathComponent("test_basketball.mp4")
            let MP4URL = resourcesURL.appendingPathComponent("test_basketball.MP4")
            
            if FileManager.default.fileExists(atPath: mp4URL.path) {
                print("✅ 找到视频: \(mp4URL.path)")
                return mp4URL
            }
            
            if FileManager.default.fileExists(atPath: MP4URL.path) {
                print("✅ 找到视频: \(MP4URL.path)")
                return MP4URL
            }
            
            // 列出 Resources 子目录的内容
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcesURL.path) {
                print("📋 Resources 子目录内容: \(contents)")
            }
        }
        
        // 列出主 Resources 目录的内容
        if let resourcesURL = Bundle.module.resourceURL {
            print("📂 主 Resources 目录: \(resourcesURL.path)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcesURL.path) {
                print("📋 主目录内容: \(contents)")
            }
        }
        
        print("⚠️ Bundle.module 中未找到视频")
        #endif
        
        // 方法2: 使用临时目录中的测试视频
        let tempDir = FileManager.default.temporaryDirectory
        let tempVideoURL = tempDir.appendingPathComponent("test_basketball.mp4")
        print("🔍 尝试临时目录: \(tempVideoURL.path)")
        return tempVideoURL
    }
    
    /// 创建测试输出目录
    private func createTestOutputDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = tempDir.appendingPathComponent("VideoAnalysisSDK_Test_Output")
        
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        return outputDir
    }
    
    /// 创建模拟的ML模型（用于测试）
    private func createMockMLModel() throws -> MLModel {
        // 注意：这是一个占位方法
        // 实际测试时需要：
        // 1. 使用真实的CoreML模型文件
        // 2. 或者创建一个简单的测试模型
        
        print("🔍 尝试加载测试模型...")
        
        // 尝试从Bundle加载模型
        #if SWIFT_PACKAGE
        // 尝试在 Resources 子目录中查找 best.mlpackage
        if let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("Resources") {
            let mlpackageURL = resourcesURL.appendingPathComponent("best.mlpackage")
            
            if FileManager.default.fileExists(atPath: mlpackageURL.path) {
                print("📦 找到模型: \(mlpackageURL.path)")
                print("🔨 正在编译模型...")
                
                do {
                    // 编译模型
                    let compiledURL = try MLModel.compileModel(at: mlpackageURL)
                    print("✅ 模型编译完成: \(compiledURL.path)")
                    
                    return try MLModel(contentsOf: compiledURL)
                } catch {
                    print("❌ 模型编译失败: \(error)")
                }
            }
        }
        
        // 尝试加载 best.mlpackage（直接从 Bundle）
        if let modelURL = Bundle.module.url(forResource: "best", withExtension: "mlpackage") {
            print("📦 找到模型: \(modelURL.path)")
            print("🔨 正在编译模型...")
            
            do {
                // 编译模型
                let compiledURL = try MLModel.compileModel(at: modelURL)
                print("✅ 模型编译完成: \(compiledURL.path)")
                
                return try MLModel(contentsOf: compiledURL)
            } catch {
                print("❌ 模型编译失败: \(error)")
            }
        }
        
        // 尝试加载已编译的 best.mlmodelc
        if let modelURL = Bundle.module.url(forResource: "best", withExtension: "mlmodelc") {
            print("📦 找到已编译模型: \(modelURL.path)")
            return try MLModel(contentsOf: modelURL)
        }
        
        // 尝试在 Resources 子目录中查找 best.mlmodelc
        if let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("Resources") {
            let mlmodelcURL = resourcesURL.appendingPathComponent("best.mlmodelc")
            
            if FileManager.default.fileExists(atPath: mlmodelcURL.path) {
                print("📦 找到已编译模型: \(mlmodelcURL.path)")
                return try MLModel(contentsOf: mlmodelcURL)
            }
        }
        
        // 列出 Resources 目录内容以便调试
        if let resourcesURL = Bundle.module.resourceURL?.appendingPathComponent("Resources") {
            print("📂 Resources 目录: \(resourcesURL.path)")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcesURL.path) {
                print("📋 目录内容: \(contents)")
            }
        }
        #endif
        
        // 如果没有模型，抛出错误
        print("❌ 未找到测试模型")
        throw VideoAnalysisError.modelNotFound("测试模型")
    }
    
    // MARK: - 调试测试
    
    /// 调试测试：查看模型输出的标签
    func testDebugModelOutput() throws {
        let testVideoURL = createTestVideoURL()
        
        guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
            throw XCTSkip("测试视频不存在")
        }
        
        let mockModel = try createMockMLModel()
        let inferenceService = VideoAnalysisSDK.createInferenceService(
            model: mockModel,
            config: InferenceConfig(confidenceThreshold: 0.1) // 降低阈值看更多检测
        )
        
        // 读取视频的第一帧
        let asset = AVAsset(url: testVideoURL)
        guard let reader = try? AVAssetReader(asset: asset),
              let track = asset.tracks(withMediaType: .video).first else {
            throw XCTSkip("无法读取视频")
        }
        
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(readerOutput)
        reader.startReading()
        
        var frameCount = 0
        var allLabels = Set<String>()
        
        print("\n" + String(repeating: "=", count: 50))
        print("🔍 模型输出调试")
        print(String(repeating: "=", count: 50))
        
        // 检查前100帧
        while frameCount < 100, let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            
            let objects = inferenceService.performInference(pixelBuffer: pixelBuffer, orientation: .up)
            
            if !objects.isEmpty && frameCount % 10 == 0 {
                print("\n📸 帧 #\(frameCount):")
                for obj in objects.prefix(5) {
                    print("   - \(obj.label): \(String(format: "%.2f", obj.confidence))")
                    allLabels.insert(obj.label.lowercased())
                }
            }
            
            frameCount += 1
        }
        
        reader.cancelReading()
        
        print("\n" + String(repeating: "=", count: 50))
        print("📊 检测到的所有标签:")
        print(String(repeating: "=", count: 50))
        for label in allLabels.sorted() {
            print("   - \(label)")
        }
        print(String(repeating: "=", count: 50) + "\n")
        
        // 检查是否有篮球相关的标签
        let basketballLabels = allLabels.filter { $0.contains("ball") || $0.contains("basket") || $0.contains("sport") }
        let rimLabels = allLabels.filter { $0.contains("rim") || $0.contains("hoop") || $0.contains("basket") }
        
        print("🏀 篮球相关标签: \(basketballLabels)")
        print("🎯 篮筐相关标签: \(rimLabels)")
        
        XCTAssertFalse(allLabels.isEmpty, "应该检测到一些物体")
    }

}
