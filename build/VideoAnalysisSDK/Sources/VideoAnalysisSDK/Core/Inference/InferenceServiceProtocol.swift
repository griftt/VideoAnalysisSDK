//
//  InferenceServiceProtocol.swift
//  VideoAnalysisSDK
//
//  推理服务协议

import Foundation
import CoreVideo
import ImageIO

/// 推理服务协议
public protocol InferenceServiceProtocol: AnyObject {
    
    /// 执行推理（同步）
    func performInference(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> [DetectedObject]
    
    /// 执行推理（异步）
    func performInferenceAsync(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        completion: @escaping (Result<[DetectedObject], Error>) -> Void
    )
}

/// 默认实现
public extension InferenceServiceProtocol {
    
    func performInferenceAsync(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        completion: @escaping (Result<[DetectedObject], Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performInference(
                pixelBuffer: pixelBuffer,
                orientation: orientation
            )
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
}
