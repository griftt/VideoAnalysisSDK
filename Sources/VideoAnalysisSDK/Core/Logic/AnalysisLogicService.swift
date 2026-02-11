//
//  AnalysisLogicService.swift
//  VideoAnalysisSDK
//
//  分析逻辑服务（可扩展为不同的检测逻辑）

import Foundation
import CoreGraphics

/// 分析逻辑服务
/// 负责处理检测逻辑，可以扩展为不同的场景（篮球、足球、其他运动等）
public class AnalysisLogicService {
    
    private let config: VideoAnalysisConfig
    
    // 校准状态
    private(set) var isCalibrated = false
    private var calibrationBuffer: [CGRect] = []
    private var targetBox: CGRect?
    private var targetZone: CGRect?
    
    // 事件检测状态
    private var lastInteractionTime: TimeInterval = -10.0
    private var lastEventTime: TimeInterval = -10.0
    
    // 标签配置（可扩展）
    private let targetLabels: Set<String>
    private let objectLabels: Set<String>
    
    // 日志回调
    private var logCallback: ((String) -> Void)?
    
    public init(config: VideoAnalysisConfig, targetLabels: Set<String> = ["rim", "hoop", "basket"], objectLabels: Set<String> = ["ball", "basketball"]) {
        self.config = config
        self.targetLabels = targetLabels
        self.objectLabels = objectLabels
        
        if config.debugMode {
            print("\n🎯 初始化分析逻辑服务")
            print("   • 目标标签: \(targetLabels.joined(separator: ", "))")
            print("   • 对象标签: \(objectLabels.joined(separator: ", "))")
            print("   • 校准帧数: \(config.calibrationFrames)")
            print("   • 事件窗口: \(config.eventWindow)s")
            print("   • 事件冷却: \(config.eventCooldown)s")
            print("   • 目标区域高度: \(config.targetZoneHeight)")
            print("   • 交互距离阈值: \(config.interactionDistanceThreshold)\n")
        }
    }
    
    public func setLogCallback(_ callback: @escaping (String) -> Void) {
        self.logCallback = callback
    }
    
    private func log(_ message: String) {
        if config.debugMode {
            logCallback?(message)
        }
    }
    
    /// 处理每一帧的检测结果
    public func processFrame(objects: [DetectedObject], timestamp: TimeInterval) -> AnalysisEvent? {
        if !isCalibrated {
            return processCalibration(objects: objects)
        } else {
            return processEventDetection(objects: objects, timestamp: timestamp)
        }
    }
    
    // MARK: - 校准逻辑
    
    private func processCalibration(objects: [DetectedObject]) -> AnalysisEvent? {
        let targets = objects.filter { targetLabels.contains($0.label.lowercased()) }
        
        if config.debugMode && calibrationBuffer.count % 5 == 0 {
            let allLabels = objects.map { $0.label }.joined(separator: ", ")
            log("🔍 帧检测: 总对象=\(objects.count) [\(allLabels)], 目标对象=\(targets.count)")
        }
        
        if let bestTarget = targets.max(by: { $0.confidence < $1.confidence }) {
            calibrationBuffer.append(bestTarget.boundingBox.rect)
            
            if config.debugMode && calibrationBuffer.count % 5 == 0 {
                log("✅ 校准样本 \(calibrationBuffer.count)/\(config.calibrationFrames): \(bestTarget.label) (置信度: \(String(format: "%.2f", bestTarget.confidence)))")
            }
            
            if calibrationBuffer.count < config.calibrationFrames {
                return .calibrating(
                    currentSamples: calibrationBuffer.count,
                    targetSamples: config.calibrationFrames
                )
            }
        }
        
        if calibrationBuffer.count >= config.calibrationFrames {
            finalizeCalibration()
            return .calibrated(box: self.targetBox ?? .zero)
        }
        
        return nil
    }
    
    private func finalizeCalibration() {
        let count = CGFloat(calibrationBuffer.count)
        let avgX = calibrationBuffer.map { $0.origin.x }.reduce(0, +) / count
        let avgY = calibrationBuffer.map { $0.origin.y }.reduce(0, +) / count
        let avgW = calibrationBuffer.map { $0.size.width }.reduce(0, +) / count
        let avgH = calibrationBuffer.map { $0.size.height }.reduce(0, +) / count
        
        let lockedBox = CGRect(x: avgX, y: avgY, width: avgW, height: avgH)
        self.targetBox = lockedBox
        
        // 计算目标区域
        self.targetZone = CGRect(
            x: lockedBox.minX - config.targetZoneHorizontalExpansion,
            y: lockedBox.minY - config.targetZoneHeight,
            width: lockedBox.width + (config.targetZoneHorizontalExpansion * 2),
            height: config.targetZoneHeight
        )
        
        self.isCalibrated = true
        self.calibrationBuffer.removeAll()
    }
    
    // MARK: - 事件检测逻辑
    
    private func processEventDetection(objects: [DetectedObject], timestamp: TimeInterval) -> AnalysisEvent? {
        // 冷却时间检查
        if timestamp - lastEventTime < config.eventCooldown {
            return nil
        }
        
        // 获取所有检测到的对象
        let targets = objects.filter { targetLabels.contains($0.label.lowercased()) }
        let detectedObjects = objects.filter { objectLabels.contains($0.label.lowercased()) }
        
        // 详细日志：显示所有检测到的对象
        if config.debugMode {
            let minutes = Int(timestamp) / 60
            let seconds = Int(timestamp) % 60
            log("\n📊 [时间 \(minutes):\(String(format: "%02d", seconds)) | \(String(format: "%.2f", timestamp))s]")
            log("   检测到: 篮筐×\(targets.count), 篮球×\(detectedObjects.count)")
            
            // 显示篮筐信息
            if !targets.isEmpty {
                for target in targets {
                    log("   🪵 篮筐: \(target.label) (置信度: \(String(format: "%.2f", target.confidence))) at (\(String(format: "%.3f", target.boundingBox.centerX)), \(String(format: "%.3f", target.boundingBox.centerY)))")
                }
            }
            
            // 显示篮球信息
            if !detectedObjects.isEmpty {
                for obj in detectedObjects {
                    log("   ⚽ 篮球: \(obj.label) (置信度: \(String(format: "%.2f", obj.confidence))) at (\(String(format: "%.3f", obj.boundingBox.centerX)), \(String(format: "%.3f", obj.boundingBox.centerY)))")
                }
            }
        }
        
        var objectInTargetZone = false
        var hasInteraction = false
        var interactionDetails: [String] = []
        
        for object in detectedObjects {
            let center = CGPoint(x: object.boundingBox.centerX, y: object.boundingBox.centerY)
            
            // 检测交互
            if let target = self.targetBox {
                let targetCenter = CGPoint(x: target.midX, y: target.midY)
                let distance = sqrt(pow(center.x - targetCenter.x, 2) + pow(center.y - targetCenter.y, 2))
                
                if distance < config.interactionDistanceThreshold {
                    self.lastInteractionTime = timestamp
                    hasInteraction = true
                    interactionDetails.append("距离检测: \(String(format: "%.3f", distance))")
                    if config.debugMode {
                        log("   ⚡ 交互检测: 距离=\(String(format: "%.3f", distance)) < 阈值=\(config.interactionDistanceThreshold)")
                    }
                }
                
                // 扩展区域检测
                let expandedRect = CGRect(
                    x: target.minX - config.expansionFactor,
                    y: target.minY - config.expansionFactor,
                    width: target.width + (config.expansionFactor * 2),
                    height: target.height + (config.expansionFactor * 2)
                )
                
                if expandedRect.contains(center) {
                    self.lastInteractionTime = timestamp
                    hasInteraction = true
                    interactionDetails.append("扩展区域")
                    if config.debugMode {
                        log("   📍 对象在扩展区域内")
                    }
                }
            }
            
            // 检测目标区域
            if let zone = self.targetZone, zone.contains(center) {
                objectInTargetZone = true
                if config.debugMode {
                    log("   🎯 对象进入目标区域: (\(String(format: "%.3f", center.x)), \(String(format: "%.3f", center.y)))")
                }
            }
        }
        
        // 显示当前状态
        if config.debugMode {
            log("   状态: 交互=\(hasInteraction ? "✅" : "❌"), 目标区=\(objectInTargetZone ? "✅" : "❌")")
            if hasInteraction {
                log("   交互详情: \(interactionDetails.joined(separator: ", "))")
            }
        }
        
        // 事件判定
        if objectInTargetZone && hasInteraction {
            let timeDiff = abs(timestamp - lastInteractionTime)
            if config.debugMode {
                log("   ⏱️  时间差检查: \(String(format: "%.2f", timeDiff))s (窗口: 0.0s - \(config.eventWindow)s)")
            }
            
            // 修改逻辑：允许同时满足条件（timeDiff = 0），只要不超过事件窗口
            if timeDiff <= config.eventWindow {
                self.lastEventTime = timestamp
                if config.debugMode {
                    log("   🎉 ✅ 进球判定成功！")
                }
                return .eventDetected(timestamp: timestamp, metadata: nil)
            } else if config.debugMode {
                log("   ⚠️  时间窗口不满足: \(String(format: "%.2f", timeDiff))s > \(config.eventWindow)s")
            }
        }
        
        return nil
    }
}
