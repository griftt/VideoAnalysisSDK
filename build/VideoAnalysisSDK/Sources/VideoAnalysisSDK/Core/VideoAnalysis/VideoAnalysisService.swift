//
//  VideoAnalysisService.swift
//  VideoAnalysisSDK
//
//  视频分析服务实现

import Foundation
import AVFoundation
import CoreVideo

/// 视频分析服务实现
public final class VideoAnalysisService: VideoAnalysisServiceProtocol {
    
    // MARK: - 属性
    
    private let inferenceService: InferenceServiceProtocol
    private let logicService: AnalysisLogicService
    private let clipService: VideoClipServiceProtocol?
    private let config: VideoAnalysisConfig
    
    private var callbacks: VideoAnalysisCallbacks?
    private var _isRunning = false
    private var _isPaused = false
    private let runningLock = NSLock()
    private let pauseLock = NSLock()
    
    private var eventCount = 0
    private var totalFrames = 0
    private var startTime: Date?
    
    public var isRunning: Bool {
        runningLock.lock()
        defer { runningLock.unlock() }
        return _isRunning
    }
    
    public var isPaused: Bool {
        pauseLock.lock()
        defer { pauseLock.unlock() }
        return _isPaused
    }
    
    // MARK: - 初始化
    
    public init(
        inferenceService: InferenceServiceProtocol,
        config: VideoAnalysisConfig,
        clipService: VideoClipServiceProtocol? = nil
    ) {
        self.inferenceService = inferenceService
        self.config = config
        self.logicService = AnalysisLogicService(config: config)
        self.clipService = clipService
        
        // 设置日志回调
        self.logicService.setLogCallback { [weak self] message in
            self?.notifyLog(message)
        }
    }
    
    // MARK: - 公共方法
    
    public func startAnalysis(videoURL: URL, callbacks: VideoAnalysisCallbacks) {
        guard !isRunning else { return }
        
        setRunningState(true)
        self.callbacks = callbacks
        self.eventCount = 0
        self.totalFrames = 0
        self.startTime = Date()
        
        // 打印配置信息
        notifyLog("\n" + String(repeating: "=", count: 60))
        notifyLog("🎬 开始视频分析")
        notifyLog(String(repeating: "=", count: 60))
        notifyLog("📹 视频文件: \(videoURL.lastPathComponent)")
        notifyLog("📊 配置信息:")
        notifyLog("   • 推理配置:")
        notifyLog("     - 置信度阈值: \(config.inferenceConfig.confidenceThreshold)")
        notifyLog("     - NMS阈值: \(config.inferenceConfig.nmsThreshold)")
        notifyLog("     - 最大检测数: \(config.inferenceConfig.maxDetections)")
        notifyLog("     - 标签过滤: \(config.inferenceConfig.labelFilter?.joined(separator: ", ") ?? "无")")
        notifyLog("   • 分析配置:")
        notifyLog("     - 跳帧数: \(config.frameSkip)")
        notifyLog("     - 校准帧数: \(config.calibrationFrames)")
        notifyLog("     - 时间范围: \(config.startTime.map { "\($0)s" } ?? "0s") - \(config.endTime.map { "\($0)s" } ?? "结束")")
        notifyLog("     - 事件窗口: \(config.eventWindow)s")
        notifyLog("     - 事件冷却: \(config.eventCooldown)s")
        notifyLog("     - 目标区域高度: \(config.targetZoneHeight)")
        notifyLog("     - 交互距离阈值: \(config.interactionDistanceThreshold)")
        notifyLog("   • 调试模式: \(config.debugMode ? "开启" : "关闭")")
        notifyLog(String(repeating: "=", count: 60) + "\n")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.runAnalysisLoop(videoURL: videoURL)
        }
    }
    
    public func stop() {
        setRunningState(false)
        setPausedState(false)
        notifyLog("🛑 分析已停止")
    }
    
    public func pause() {
        setPausedState(true)
        notifyLog("⏸️ 分析已暂停")
    }
    
    public func resume() {
        setPausedState(false)
        notifyLog("▶️ 分析已恢复")
    }
    
    // MARK: - 私有方法
    
    private func runAnalysisLoop(videoURL: URL) {
        autoreleasepool {
            do {
                try performAnalysis(videoURL: videoURL)
            } catch {
                notifyError(error)
            }
        }
    }
    
    private func performAnalysis(videoURL: URL) throws {
        notifyLog("📂 正在加载视频资源...")
        let asset = AVAsset(url: videoURL)
        
        guard let reader = try? AVAssetReader(asset: asset),
              let track = asset.tracks(withMediaType: .video).first else {
            throw VideoAnalysisError.readerCreationFailed("无法创建读取器或找不到视频轨道")
        }
        
        let orientation = getOrientation(from: track)
        let videoDuration = asset.duration.seconds
        let startTime = config.startTime ?? 0.0
        let endTime = config.endTime ?? videoDuration
        
        notifyLog("✅ 视频加载成功")
        notifyLog("   • 总时长: \(String(format: "%.2f", videoDuration))秒")
        notifyLog("   • 分析范围: \(String(format: "%.2f", startTime))s - \(String(format: "%.2f", endTime))s")
        notifyLog("   • 视频方向: \(orientation)")
        
        guard startTime < endTime && startTime >= 0 && endTime <= videoDuration else {
            throw VideoAnalysisError.invalidTimeRange
        }
        
        let timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            duration: CMTime(seconds: endTime - startTime, preferredTimescale: 600)
        )
        reader.timeRange = timeRange
        
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: 1280,
            kCVPixelBufferHeightKey as String: 720
        ]
        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(readerOutput)
        
        guard reader.startReading() else {
            throw VideoAnalysisError.readerCreationFailed(reader.error?.localizedDescription ?? "未知错误")
        }
        
        notifyLog("\n🚀 开始逐帧分析...")
        notifyLog("   • 输出分辨率: 1280x720")
        notifyLog("   • 跳帧策略: 每\(config.frameSkip)帧处理一次\n")
        
        var frameIndex = 0
        let totalDuration = endTime - startTime
        var shouldComplete = false
        
        while isRunning && !shouldComplete {
            autoreleasepool {
                while isPaused && isRunning {
                    Thread.sleep(forTimeInterval: 0.1)
                }
                
                guard isRunning else { 
                    shouldComplete = true
                    return 
                }
                
                guard let sampleBuffer = readerOutput.copyNextSampleBuffer(),
                      let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    shouldComplete = true
                    return
                }
                
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
                
                // 跳帧策略
                if logicService.isCalibrated && frameIndex % config.frameSkip != 0 {
                    frameIndex += 1
                    return
                }
                
                // 执行推理
                let objects = inferenceService.performInference(
                    pixelBuffer: pixelBuffer,
                    orientation: orientation
                )
                
                // 每100帧打印一次推理统计
                if config.debugMode && frameIndex % 100 == 0 && frameIndex > 0 {
                    notifyLog("📊 帧 #\(frameIndex): 检测到 \(objects.count) 个对象")
                }
                
                // 处理逻辑
                if let event = logicService.processFrame(objects: objects, timestamp: timestamp) {
                    handleEvent(event, videoURL: videoURL)
                }
                
                // 更新进度
                if frameIndex % 30 == 0 {
                    let relativeTime = timestamp - startTime
                    let progress = (relativeTime / totalDuration) * 0.95
                    notifyProgress(min(progress, 0.95))
                }
                
                frameIndex += 1
                totalFrames += 1
            }
        }
        
        reader.cancelReading()
        setRunningState(false)
        
        // 立即报告完成，不等待剪辑
        let duration = Date().timeIntervalSince(self.startTime ?? Date())
        let result = AnalysisResult(
            events: [],
            totalFrames: totalFrames,
            duration: duration
        )
        
        notifyProgress(1.0)
        notifyLog("\n" + String(repeating: "=", count: 60))
        notifyLog("✅ 视频分析完成")
        notifyLog("📊 统计信息:")
        notifyLog("   • 处理帧数: \(totalFrames)")
        notifyLog("   • 处理时长: \(String(format: "%.2f", duration))秒")
        notifyLog("   • 平均FPS: \(String(format: "%.2f", result.averageFPS))")
        notifyLog("   • 检测事件数: \(eventCount)")
        notifyLog(String(repeating: "=", count: 60) + "\n")
        notifyCompletion(result)
    }
    
    private func handleEvent(_ event: AnalysisEvent, videoURL: URL) {
        notifyEvent(event)
        
        switch event {
        case .calibrating(let current, let target):
            if current == 1 {
                notifyLog("\n🎯 开始校准阶段...")
                notifyLog("   • 目标样本数: \(target)")
            }
            if current % 10 == 0 {
                let progress = Double(current) / Double(target) * 100
                notifyLog("   🟢 校准进度: \(current)/\(target) (\(String(format: "%.0f", progress))%)")
            }
            
        case .calibrated(let box):
            notifyLog("\n✅ 校准完成！")
            notifyLog("   • 目标位置: x=\(String(format: "%.3f", box.origin.x)), y=\(String(format: "%.3f", box.origin.y))")
            notifyLog("   • 目标大小: w=\(String(format: "%.3f", box.size.width)), h=\(String(format: "%.3f", box.size.height))")
            notifyLog("\n🔍 开始事件检测阶段...\n")
            
        case .eventDetected(let timestamp, _):
            eventCount += 1
            let minutes = Int(timestamp) / 60
            let seconds = Int(timestamp) % 60
            notifyLog("\n🎯 检测到事件 #\(eventCount)")
            notifyLog("   • 时间戳: \(String(format: "%.2f", timestamp))秒 (\(minutes):\(String(format: "%02d", seconds)))")
            
            // 触发剪辑
            if let clipService = clipService {
                notifyLog("   ✂️  开始剪辑...")
                clipService.exportClip(
                    from: videoURL,
                    at: timestamp,
                    index: eventCount
                ) { [weak self] result in
                    switch result {
                    case .success(let clipResult):
                        self?.notifyClipCreated(clipResult)
                    case .failure(let error):
                        self?.notifyLog("   ❌ 剪辑失败: \(error.localizedDescription)")
                    }
                }
            } else {
                notifyLog("   ℹ️  未配置剪辑服务，跳过剪辑")
            }
            
        case .custom(let name, _):
            notifyLog("📌 自定义事件: \(name)")
        }
    }
    
    // MARK: - 辅助方法
    
    private func setRunningState(_ state: Bool) {
        runningLock.lock()
        _isRunning = state
        runningLock.unlock()
    }
    
    private func setPausedState(_ state: Bool) {
        pauseLock.lock()
        _isPaused = state
        pauseLock.unlock()
    }
    
    private func getOrientation(from track: AVAssetTrack) -> CGImagePropertyOrientation {
        let t = track.preferredTransform
        if t.a == 0 && t.b == 1.0 && t.c == -1.0 { return .right }
        if t.a == 0 && t.b == -1.0 && t.c == 1.0 { return .left }
        if t.a == 1.0 && t.b == 0 && t.c == 0 { return .up }
        if t.a == -1.0 && t.b == 0 && t.c == 0 { return .down }
        return .up
    }
    
    // MARK: - 通知方法
    
    private func notifyLog(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.callbacks?.onLog?(message)
        }
    }
    
    private func notifyProgress(_ value: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.callbacks?.onProgress?(value)
        }
    }
    
    private func notifyEvent(_ event: AnalysisEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.callbacks?.onEvent?(event)
        }
    }
    
    private func notifyClipCreated(_ result: ClipResult) {
        DispatchQueue.main.async { [weak self] in
            self?.callbacks?.onClipCreated?(result)
        }
    }
    
    private func notifyCompletion(_ result: AnalysisResult) {
        DispatchQueue.main.async { [weak self] in
            self?.callbacks?.onCompletion?(result)
        }
    }
    
    private func notifyError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.callbacks?.onError?(error)
        }
    }
}
