//
//  VideoClipService.swift
//  VideoAnalysisSDK
//
//  视频剪辑服务实现

import Foundation
import AVFoundation

/// 视频剪辑服务实现
public final class VideoClipService: VideoClipServiceProtocol {
    
    private let config: VideoClipConfig
    private let outputDirectory: URL
    private let exportSemaphore: DispatchSemaphore
    private var activeSessions: [AVAssetExportSession] = []
    private let sessionsLock = NSLock()
    
    public init(config: VideoClipConfig = .default) {
        self.config = config
        self.exportSemaphore = DispatchSemaphore(value: config.maxConcurrentExports)
        
        // 确定输出目录
        if let customDir = config.outputDirectory {
            self.outputDirectory = customDir
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let baseDir = docs.appendingPathComponent("VideoClips")
            
            if let sessionName = config.sessionName {
                self.outputDirectory = baseDir.appendingPathComponent(sessionName)
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let timestamp = dateFormatter.string(from: Date())
                self.outputDirectory = baseDir.appendingPathComponent("Session_\(timestamp)")
            }
        }
        
        // 创建输出目录
        try? FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        
        print("\n✂️  初始化剪辑服务")
        print("   • 前置时间: \(config.leadTime)s")
        print("   • 后置时间: \(config.trailTime)s")
        print("   • 最大并发数: \(config.maxConcurrentExports)")
        print("   • 输出目录: \(outputDirectory.path)\n")
    }
    
    public func exportClip(
        from sourceURL: URL,
        at timestamp: TimeInterval,
        index: Int,
        completion: @escaping (Result<ClipResult, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.exportSemaphore.wait()
            
            autoreleasepool {
                self.performExport(
                    from: sourceURL,
                    at: timestamp,
                    index: index,
                    completion: { result in
                        self.exportSemaphore.signal()
                        completion(result)
                    }
                )
            }
        }
    }
    
    public func cancelAll() {
        sessionsLock.lock()
        let sessions = activeSessions
        activeSessions.removeAll()
        sessionsLock.unlock()
        
        sessions.forEach { $0.cancelExport() }
    }
    
    // MARK: - 私有方法
    
    private func performExport(
        from sourceURL: URL,
        at timestamp: TimeInterval,
        index: Int,
        completion: @escaping (Result<ClipResult, Error>) -> Void
    ) {
        let asset = AVAsset(url: sourceURL)
        
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            completion(.failure(VideoAnalysisError.exportFailed("无法创建导出会话")))
            return
        }
        
        // 添加到活动会话列表
        sessionsLock.lock()
        activeSessions.append(session)
        sessionsLock.unlock()
        
        let filename = "clip_\(index)_\(Int(timestamp))s.mp4"
        let outputURL = outputDirectory.appendingPathComponent(filename)
        
        let videoDuration = asset.duration.seconds
        let start = max(0, timestamp - config.leadTime)
        let end = min(videoDuration, timestamp + config.trailTime)
        let duration = end - start
        
        print("   ✂️  剪辑 #\(index):")
        print("      • 时间戳: \(String(format: "%.2f", timestamp))s")
        print("      • 范围: \(String(format: "%.2f", start))s - \(String(format: "%.2f", end))s")
        print("      • 时长: \(String(format: "%.2f", duration))s")
        print("      • 文件名: \(filename)")
        
        guard duration > 0 else {
            completion(.failure(VideoAnalysisError.invalidTimeRange))
            return
        }
        
        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.timeRange = CMTimeRange(
            start: CMTime(seconds: start, preferredTimescale: 600),
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )
        
        // 移除已存在的文件
        try? FileManager.default.removeItem(at: outputURL)
        
        // 设置超时
        let timeoutWorkItem = DispatchWorkItem {
            session.cancelExport()
        }
        DispatchQueue.global(qos: .background).asyncAfter(
            deadline: .now() + config.exportTimeout,
            execute: timeoutWorkItem
        )
        
        let exportStartTime = Date()
        
        session.exportAsynchronously { [weak self] in
            guard let self = self else { return }
            
            timeoutWorkItem.cancel()
            
            // 从活动会话列表移除
            self.sessionsLock.lock()
            self.activeSessions.removeAll { $0 === session }
            self.sessionsLock.unlock()
            
            let exportDuration = Date().timeIntervalSince(exportStartTime)
            
            DispatchQueue.main.async {
                switch session.status {
                case .completed:
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
                        let fileSize = attributes[.size] as? Int64 ?? 0
                        
                        print("      ✅ 剪辑完成 (耗时: \(String(format: "%.2f", exportDuration))s)")
                        print("      • 文件大小: \(fileSize / 1024 / 1024)MB")
                        print("      • 保存路径: \(outputURL.path)\n")
                        
                        let result = ClipResult(
                            url: outputURL,
                            index: index,
                            timestamp: timestamp,
                            duration: duration,
                            fileSize: fileSize
                        )
                        completion(.success(result))
                    } catch {
                        print("      ❌ 获取文件信息失败: \(error.localizedDescription)\n")
                        completion(.failure(error))
                    }
                    
                case .failed:
                    let error = session.error ?? VideoAnalysisError.exportFailed("未知错误")
                    print("      ❌ 剪辑失败: \(error.localizedDescription)\n")
                    completion(.failure(error))
                    
                case .cancelled:
                    print("      ⚠️ 剪辑已取消\n")
                    completion(.failure(VideoAnalysisError.cancelled))
                    
                default:
                    print("      ❌ 导出状态异常\n")
                    completion(.failure(VideoAnalysisError.unknown("导出状态异常")))
                }
            }
        }
    }
}
