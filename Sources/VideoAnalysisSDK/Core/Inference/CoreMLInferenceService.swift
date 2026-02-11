//
//  CoreMLInferenceService.swift
//  VideoAnalysisSDK
//
//  CoreML 推理服务实现

import Foundation
import Vision
import CoreML
import CoreVideo
import ImageIO

/// CoreML 推理服务实现
public final class CoreMLInferenceService: InferenceServiceProtocol {
    
    private let model: MLModel
    private let config: InferenceConfig
    private var request: VNCoreMLRequest?
    private let inferenceQueue = DispatchQueue(
        label: "com.videoanalysissdk.inference",
        qos: .userInitiated
    )
    
    public init(model: MLModel, config: InferenceConfig = .default) {
        self.model = model
        self.config = config
        print("\n🧠 初始化推理服务")
        print("   • 置信度阈值: \(config.confidenceThreshold)")
        print("   • NMS阈值: \(config.nmsThreshold)")
        print("   • 最大检测数: \(config.maxDetections)")
        print("   • 内存优化: \(config.enableMemoryOptimization ? "开启" : "关闭")")
        if let filter = config.labelFilter {
            print("   • 标签过滤: \(filter.joined(separator: ", "))")
        }
        setupRequest()
    }
    
    public func performInference(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation = .up
    ) -> [DetectedObject] {
        guard let request = self.request else { return [] }
        
        let performInference = {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: orientation
            )
            
            do {
                try handler.perform([request])
            } catch {
                print("⚠️ VideoAnalysisSDK: 推理失败 - \(error.localizedDescription)")
                return [DetectedObject]()
            }
            
            let observations = (request.results as? [VNRecognizedObjectObservation]) ?? []
            return self.processObservations(observations)
        }
        
        if config.enableMemoryOptimization {
            return autoreleasepool { performInference() }
        } else {
            return performInference()
        }
    }
    
    private func setupRequest() {
        guard let visionModel = try? VNCoreMLModel(for: model) else {
            print("❌ 无法创建 Vision 模型")
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFit
        self.request = request
        print("✅ 推理模型加载成功\n")
    }
    
    private func processObservations(_ observations: [VNRecognizedObjectObservation]) -> [DetectedObject] {
        var results = observations
            .filter { $0.confidence >= config.confidenceThreshold }
            .map { DetectedObject(from: $0) }
        
        let originalCount = results.count
        
        if let labelFilter = config.labelFilter {
            // 不区分大小写的标签过滤
            let lowercaseFilter = Set(labelFilter.map { $0.lowercased() })
            results = results.filter { lowercaseFilter.contains($0.label.lowercased()) }
        }
        
        if results.count > config.maxDetections {
            results = Array(results.prefix(config.maxDetections))
        }
        
        results = applyNMS(to: results)
        
        return results
    }
    
    private func applyNMS(to objects: [DetectedObject]) -> [DetectedObject] {
        guard objects.count > 1 else { return objects }
        
        let sorted = objects.sorted { $0.confidence > $1.confidence }
        var selected = [DetectedObject]()
        var suppressed = Set<Int>()
        
        for (i, object) in sorted.enumerated() {
            if suppressed.contains(i) { continue }
            selected.append(object)
            
            for (j, other) in sorted.enumerated() where j > i {
                if suppressed.contains(j) { continue }
                let iou = object.boundingBox.iou(with: other.boundingBox)
                if iou > CGFloat(config.nmsThreshold) {
                    suppressed.insert(j)
                }
            }
        }
        
        return selected
    }
}
