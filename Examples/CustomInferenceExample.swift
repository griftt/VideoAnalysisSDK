import Foundation
import VideoAnalysisSDK

/// 示例：使用云端 API 推理服务
class CloudAPIInferenceExample {
    
    func runWithCloudAPI(videoURL: URL) {
        do {
            // 1. 配置云端 API
            let apiConfig = CloudAPIInferenceService.APIConfig(
                endpoint: URL(string: "https://api.example.com/v1/detect")!,
                apiKey: "your-api-key-here",
                timeout: 30.0,
                imageQuality: 0.8,
                maxImageSize: CGSize(width: 1280, height: 720)
            )
            
            // 2. 创建云端推理服务
            let cloudInferenceService = CloudAPIInferenceService(
                apiConfig: apiConfig,
                inferenceConfig: InferenceConfig(
                    confidenceThreshold: 0.15,
                    labelFilter: ["basketball", "rim"]
                )
            )
            
            // 3. 配置视频分析
            let analysisConfig = VideoAnalysisConfig(
                inferenceConfig: InferenceConfig(
                    confidenceThreshold: 0.15,
                    labelFilter: ["basketball", "rim"]
                ),
                frameSkip: 3,
                calibrationFrames: 30
            )
            
            // 4. 配置剪辑
            let clipConfig = VideoClipConfig(
                leadTime: 4.0,
                trailTime: 2.0,
                sessionName: "CloudAPIHighlights"
            )
            
            // 5. 创建分析服务（使用云端推理）
            let clipService = VideoAnalysisSDK.createVideoClipService(config: clipConfig)
            let analysisService = VideoAnalysisService(
                inferenceService: cloudInferenceService,  // 使用云端推理服务
                config: analysisConfig,
                clipService: clipService
            )
            
            // 6. 设置回调
            let callbacks = VideoAnalysisCallbacks(
                onLog: { print("📝 \($0)") },
                onProgress: { print("📊 进度: \(Int($0 * 100))%") },
                onClipCreated: { print("✂️ 集锦 #\($0.index) 已生成") }
            )
            
            // 7. 开始分析
            analysisService.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("❌ 错误: \(error)")
        }
    }
}

/// 示例：自定义推理服务
/// 实现 InferenceServiceProtocol 协议即可
class CustomInferenceService: InferenceServiceProtocol {
    
    func performInference(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> [DetectedObject] {
        // 实现你的自定义推理逻辑
        // 例如：调用其他推理引擎、使用缓存、批量处理等
        
        print("🔧 使用自定义推理服务")
        
        // 返回检测结果
        return []
    }
    
    func performInferenceAsync(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        completion: @escaping (Result<[DetectedObject], Error>) -> Void
    ) {
        // 实现异步推理
        DispatchQueue.global().async {
            let result = self.performInference(pixelBuffer: pixelBuffer, orientation: orientation)
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
}

/// 示例：混合推理服务（本地 + 云端）
/// 本地快速检测，云端精确检测
class HybridInferenceService: InferenceServiceProtocol {
    
    private let localService: InferenceServiceProtocol
    private let cloudService: InferenceServiceProtocol
    private let useCloudThreshold: Float
    
    init(
        localService: InferenceServiceProtocol,
        cloudService: InferenceServiceProtocol,
        useCloudThreshold: Float = 0.3
    ) {
        self.localService = localService
        self.cloudService = cloudService
        self.useCloudThreshold = useCloudThreshold
    }
    
    func performInference(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> [DetectedObject] {
        // 1. 先用本地模型快速检测
        let localResults = localService.performInference(
            pixelBuffer: pixelBuffer,
            orientation: orientation
        )
        
        // 2. 如果本地检测置信度低，使用云端模型
        let maxConfidence = localResults.map { $0.confidence }.max() ?? 0
        
        if maxConfidence < useCloudThreshold {
            print("🌐 本地置信度低，使用云端推理")
            return cloudService.performInference(
                pixelBuffer: pixelBuffer,
                orientation: orientation
            )
        }
        
        return localResults
    }
    
    func performInferenceAsync(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        completion: @escaping (Result<[DetectedObject], Error>) -> Void
    ) {
        // 异步混合推理
        localService.performInferenceAsync(
            pixelBuffer: pixelBuffer,
            orientation: orientation
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let localResults):
                let maxConfidence = localResults.map { $0.confidence }.max() ?? 0
                
                if maxConfidence < self.useCloudThreshold {
                    // 使用云端推理
                    self.cloudService.performInferenceAsync(
                        pixelBuffer: pixelBuffer,
                        orientation: orientation,
                        completion: completion
                    )
                } else {
                    completion(.success(localResults))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

/// 使用示例
class InferenceStrategyExample {
    
    func example1_LocalOnly(videoURL: URL) {
        // 策略 1: 只使用本地 CoreML
        do {
            let service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelName: "best",
                config: .default
            )
            // ...
        } catch {
            print("❌ 错误: \(error)")
        }
    }
    
    func example2_CloudOnly(videoURL: URL) {
        // 策略 2: 只使用云端 API
        let apiConfig = CloudAPIInferenceService.APIConfig(
            endpoint: URL(string: "https://api.example.com/detect")!,
            apiKey: "your-api-key"
        )
        
        let cloudService = CloudAPIInferenceService(
            apiConfig: apiConfig,
            inferenceConfig: .default
        )
        
        let analysisService = VideoAnalysisService(
            inferenceService: cloudService,
            config: .default,
            clipService: nil
        )
        // ...
    }
    
    func example3_Hybrid(videoURL: URL) {
        // 策略 3: 混合推理（本地 + 云端）
        do {
            let localService = try VideoAnalysisSDK.createInferenceService(
                modelName: "best",
                config: .default
            )
            
            let apiConfig = CloudAPIInferenceService.APIConfig(
                endpoint: URL(string: "https://api.example.com/detect")!,
                apiKey: "your-api-key"
            )
            let cloudService = CloudAPIInferenceService(
                apiConfig: apiConfig,
                inferenceConfig: .default
            )
            
            let hybridService = HybridInferenceService(
                localService: localService,
                cloudService: cloudService,
                useCloudThreshold: 0.3
            )
            
            let analysisService = VideoAnalysisService(
                inferenceService: hybridService,
                config: .default,
                clipService: nil
            )
            // ...
        } catch {
            print("❌ 错误: \(error)")
        }
    }
}
