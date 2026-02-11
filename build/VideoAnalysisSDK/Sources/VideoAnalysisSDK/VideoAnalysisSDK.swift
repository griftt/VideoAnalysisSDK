//
//  VideoAnalysisSDK.swift
//  VideoAnalysisSDK
//
//  完整的视频分析SDK
//  包含推理、视频分析、视频剪辑功能

import Foundation
import CoreML

/// VideoAnalysisSDK 主入口
public final class VideoAnalysisSDK {
    
    /// SDK 版本
    public static let version = "1.0.0"
    
    private init() {}
    
    // MARK: - 推理服务创建
    
    /// 创建推理服务
    public static func createInferenceService(
        model: MLModel,
        config: InferenceConfig = .default
    ) -> InferenceServiceProtocol {
        return CoreMLInferenceService(model: model, config: config)
    }
    
    /// 从文件加载模型并创建推理服务
    public static func createInferenceService(
        modelURL: URL,
        config: InferenceConfig = .default
    ) throws -> InferenceServiceProtocol {
        let model = try MLModel(contentsOf: modelURL)
        return createInferenceService(model: model, config: config)
    }
    
    /// 从Bundle加载模型并创建推理服务
    public static func createInferenceService(
        modelName: String,
        bundle: Bundle = .main,
        config: InferenceConfig = .default
    ) throws -> InferenceServiceProtocol {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "mlmodelc") ??
                              bundle.url(forResource: modelName, withExtension: "mlpackage") else {
            throw VideoAnalysisError.modelNotFound(modelName)
        }
        return try createInferenceService(modelURL: modelURL, config: config)
    }
    
    // MARK: - 视频分析服务创建
    
    /// 创建视频分析服务（不带剪辑功能）
    public static func createVideoAnalysisService(
        model: MLModel,
        config: VideoAnalysisConfig
    ) -> VideoAnalysisServiceProtocol {
        let inferenceService = createInferenceService(
            model: model,
            config: config.inferenceConfig
        )
        return VideoAnalysisService(
            inferenceService: inferenceService,
            config: config,
            clipService: nil
        )
    }
    
    /// 创建视频分析服务（带剪辑功能）
    public static func createVideoAnalysisService(
        model: MLModel,
        config: VideoAnalysisConfig,
        clipConfig: VideoClipConfig
    ) -> VideoAnalysisServiceProtocol {
        let inferenceService = createInferenceService(
            model: model,
            config: config.inferenceConfig
        )
        let clipService = createVideoClipService(config: clipConfig)
        return VideoAnalysisService(
            inferenceService: inferenceService,
            config: config,
            clipService: clipService
        )
    }
    
    /// 从文件加载模型并创建视频分析服务（不带剪辑功能）
    public static func createVideoAnalysisService(
        modelURL: URL,
        config: VideoAnalysisConfig
    ) throws -> VideoAnalysisServiceProtocol {
        let model = try MLModel(contentsOf: modelURL)
        return createVideoAnalysisService(model: model, config: config)
    }
    
    /// 从文件加载模型并创建视频分析服务（带剪辑功能）
    public static func createVideoAnalysisService(
        modelURL: URL,
        config: VideoAnalysisConfig,
        clipConfig: VideoClipConfig
    ) throws -> VideoAnalysisServiceProtocol {
        let model = try MLModel(contentsOf: modelURL)
        return createVideoAnalysisService(model: model, config: config, clipConfig: clipConfig)
    }
    
    /// 从Bundle加载模型并创建视频分析服务（不带剪辑功能）
    public static func createVideoAnalysisService(
        modelName: String,
        bundle: Bundle = .main,
        config: VideoAnalysisConfig
    ) throws -> VideoAnalysisServiceProtocol {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "mlmodelc") ??
                              bundle.url(forResource: modelName, withExtension: "mlpackage") else {
            throw VideoAnalysisError.modelNotFound(modelName)
        }
        return try createVideoAnalysisService(modelURL: modelURL, config: config)
    }
    
    /// 从Bundle加载模型并创建视频分析服务（带剪辑功能）
    public static func createVideoAnalysisService(
        modelName: String,
        bundle: Bundle = .main,
        config: VideoAnalysisConfig,
        clipConfig: VideoClipConfig
    ) throws -> VideoAnalysisServiceProtocol {
        guard let modelURL = bundle.url(forResource: modelName, withExtension: "mlmodelc") ??
                              bundle.url(forResource: modelName, withExtension: "mlpackage") else {
            throw VideoAnalysisError.modelNotFound(modelName)
        }
        return try createVideoAnalysisService(modelURL: modelURL, config: config, clipConfig: clipConfig)
    }
    
    // MARK: - 视频剪辑服务创建
    
    /// 创建视频剪辑服务
    public static func createVideoClipService(
        config: VideoClipConfig = .default
    ) -> VideoClipServiceProtocol {
        return VideoClipService(config: config)
    }
}
