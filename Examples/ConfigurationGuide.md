# VideoAnalysisSDK 配置指南

## 概述

VideoAnalysisSDK 提供了灵活的配置系统，支持：
- 使用系统默认配置（开箱即用）
- 基于默认配置进行部分修改
- 完全自定义配置

## 系统默认配置

SDK 内置了经过优化的默认配置，适用于大多数篮球视频分析场景：

```swift
// 直接使用默认配置
let config = VideoAnalysisConfig.default
```

### 默认参数值

#### 推理配置
- `confidenceThreshold`: 0.15 - 置信度阈值
- `nmsThreshold`: 0.45 - NMS 阈值
- `maxDetections`: 100 - 最大检测数
- `enableMemoryOptimization`: true - 内存优化

#### 分析配置
- `frameSkip`: 3 - 跳帧数（每3帧处理一次）
- `calibrationFrames`: 30 - 校准帧数
- `eventWindow`: 2.5s - 事件检测时间窗口
- `eventCooldown`: 3.0s - 事件冷却时间
- `targetZoneHeight`: 0.06 - 目标区域高度
- `interactionDistanceThreshold`: 0.20 - 交互距离阈值

#### 标签配置
- `targetLabels`: ["rim", "1", "hoop", "basket", "class_1"] - 篮筐标签
- `objectLabels`: ["ball", "0", "basketball", "sport ball", "class_0"] - 篮球标签

#### 剪辑配置
- `leadTime`: 4.0s - 剪辑前置时间
- `trailTime`: 2.0s - 剪辑后置时间
- `maxConcurrentExports`: 2 - 最大并发剪辑数
- `exportTimeout`: 120s - 剪辑超时时间

## 使用方式

### 方式1: 使用完全默认配置

```swift
// 最简单的方式，使用所有默认值
let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
    modelURL: modelURL,
    config: .default,  // 使用默认配置
    clipConfig: .default
)
```

### 方式2: 基于默认配置进行部分修改

```swift
// 从默认配置开始，只修改需要的参数
var config = VideoAnalysisConfig.default
config.debugMode = true           // 开启调试模式
config.startTime = 400            // 从400秒开始分析
config.endTime = 600              // 到600秒结束
config.frameSkip = 5              // 改为每5帧处理一次

let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
    modelURL: modelURL,
    config: config,
    clipConfig: .default
)
```

### 方式3: 完全自定义配置

```swift
// 完全自定义所有参数
let inferenceConfig = InferenceConfig(
    confidenceThreshold: 0.2,
    nmsThreshold: 0.5,
    maxDetections: 50
)

let analysisConfig = VideoAnalysisConfig(
    inferenceConfig: inferenceConfig,
    frameSkip: 2,
    calibrationFrames: 40,
    startTime: 0,
    endTime: nil,
    eventWindow: 3.0,
    eventCooldown: 2.0,
    debugMode: true
)

let clipConfig = VideoClipConfig(
    leadTime: 5.0,
    trailTime: 3.0,
    outputDirectory: URL(fileURLWithPath: "~/Desktop/Clips")
)

let analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
    modelURL: modelURL,
    config: analysisConfig,
    clipConfig: clipConfig
)
```

## 预设配置

SDK 还提供了几个预设配置：

### 默认配置（平衡）
```swift
let config = VideoAnalysisConfig.default
```

### 高性能配置（速度优先）
```swift
let config = VideoAnalysisConfig.performance
// - 更大的跳帧数（frameSkip: 5）
// - 更少的校准帧（calibrationFrames: 20）
// - 关闭调试模式
```

### 高精度配置（准确度优先）
```swift
let config = VideoAnalysisConfig.highPrecision
// - 更小的跳帧数（frameSkip: 2）
// - 更多的校准帧（calibrationFrames: 40）
// - 更严格的检测阈值
```

## 推理配置预设

```swift
// 默认配置
let config = InferenceConfig.default

// 高精度（更严格的阈值）
let config = InferenceConfig.highPrecision

// 高召回率（更宽松的阈值）
let config = InferenceConfig.highRecall

// 高性能（更少的检测数）
let config = InferenceConfig.performance
```

## 参数调优建议

### 提高检测准确度
- 降低 `confidenceThreshold`（如 0.1）
- 增加 `calibrationFrames`（如 40-50）
- 减小 `frameSkip`（如 2）
- 减小 `targetZoneHeight`（如 0.04）

### 提高处理速度
- 增加 `frameSkip`（如 5-10）
- 减少 `calibrationFrames`（如 20）
- 增加 `confidenceThreshold`（如 0.25）
- 减少 `maxDetections`（如 50）

### 减少误检
- 增加 `confidenceThreshold`（如 0.25-0.3）
- 增加 `eventCooldown`（如 5.0s）
- 减小 `targetZoneHeight`（如 0.04）
- 减小 `interactionDistanceThreshold`（如 0.15）

### 增加检出率
- 降低 `confidenceThreshold`（如 0.1）
- 增加 `eventWindow`（如 3.0s）
- 增加 `targetZoneHeight`（如 0.08）
- 增加 `interactionDistanceThreshold`（如 0.25）

## 在 HighlightMoment 中使用

```swift
// 在 ProcessingViewModel 中
func startAnalysis(fileURL: URL, startTime: TimeInterval? = nil) {
    // 使用默认配置
    var config = VideoAnalysisConfig.default
    
    // 根据用户设置修改
    config.debugMode = self.debugMode
    config.startTime = startTime
    
    // 创建服务
    let service = try VideoAnalysisSDK.createVideoAnalysisService(
        modelURL: modelURL,
        config: config,
        clipConfig: .default
    )
    
    service.startAnalysis(videoURL: fileURL, callbacks: callbacks)
}
```

## 命令行测试工具

```bash
# 使用默认配置
swift run CompleteTest video.mp4 model.mlmodelc

# 使用默认配置并指定输出目录
swift run CompleteTest video.mp4 model.mlmodelc ~/Desktop/Clips

# 自定义配置（需要修改代码）
# 编辑 CompleteTestMain.main() 中的 config 变量
```

## 最佳实践

1. **开始时使用默认配置** - 默认配置已经过优化，适用于大多数场景
2. **逐步调整** - 如果需要优化，一次只调整一个参数
3. **记录结果** - 记录每次调整的效果，便于对比
4. **使用调试模式** - 开发时开启 `debugMode`，生产环境关闭
5. **合理设置时间范围** - 使用 `startTime` 和 `endTime` 跳过无关片段

## 常见问题

### Q: 如何知道当前使用的是什么配置？
A: 开启 `debugMode`，SDK 会在日志中打印完整的配置信息。

### Q: 可以在运行时修改配置吗？
A: 不可以。配置在创建服务时确定，运行时不可修改。需要修改配置时，请停止当前服务并创建新服务。

### Q: 默认配置适用于所有场景吗？
A: 默认配置针对标准篮球视频优化，对于特殊场景（如低分辨率、特殊角度等）可能需要调整。

### Q: 如何保存自定义配置？
A: 可以将配置参数保存到 UserDefaults 或配置文件中，在创建服务时读取并应用。
