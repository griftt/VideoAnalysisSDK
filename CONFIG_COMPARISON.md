# HighlightMoment vs VideoAnalysisSDK 配置对比

## 概述

HighlightMoment 项目和 VideoAnalysisSDK 使用了相同的核心参数值，但在结构和命名上有所不同。

## 配置结构对比

### HighlightMoment (DetectorConfig)
- **单一配置结构** - 所有参数在一个 `DetectorConfig` 结构体中
- **面向应用** - 包含 UI 相关的注释和验证
- **命名风格** - 使用更具体的业务术语（如 `shotWindow`, `rimExpansionFactor`）

### VideoAnalysisSDK (VideoAnalysisConfig)
- **分层配置结构** - 分为 `InferenceConfig`、`VideoAnalysisConfig`、`VideoClipConfig`
- **面向 SDK** - 更通用的命名，便于扩展到其他场景
- **命名风格** - 使用更通用的术语（如 `eventWindow`, `expansionFactor`）

## 详细参数对比

### 1. 推理参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `confThresRim` | `inferenceConfig.confidenceThreshold` | 0.15 | 篮筐/目标置信度阈值 |
| `confThresBall` | `inferenceConfig.confidenceThreshold` | 0.15 | 篮球/对象置信度阈值 |
| - | `inferenceConfig.nmsThreshold` | 0.45 | NMS 阈值 |
| - | `inferenceConfig.maxDetections` | 100 | 最大检测数 |
| - | `inferenceConfig.enableMemoryOptimization` | true | 内存优化 |
| - | `inferenceConfig.labelFilter` | nil | 标签过滤 |

**差异说明：**
- HighlightMoment 为篮筐和篮球分别设置置信度阈值
- SDK 使用统一的置信度阈值，更通用
- SDK 增加了 NMS、最大检测数等推理相关参数

### 2. 性能参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `frameSkip` | `frameSkip` | 3 | 跳帧数 |
| `calibrationFrames` | `calibrationFrames` | 30 | 校准帧数 |

**差异说明：** 完全一致

### 3. 时间范围参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `startTime` | `startTime` | nil | 开始时间 |
| `endTime` | `endTime` | nil | 结束时间 |

**差异说明：** 完全一致

### 4. 事件检测参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `shotWindow` | `eventWindow` | 2.5s | 事件时间窗口 |
| `shotCooldown` | `eventCooldown` | 3.0s | 事件冷却时间 |
| `minInteractionInterval` | `minInteractionInterval` | 0.05s | 最小交互间隔 |

**差异说明：**
- 命名不同：`shot` → `event`（更通用）
- 参数值完全一致

### 5. 空间判定参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `goalZoneHeight` | `targetZoneHeight` | 0.06 | 目标区域高度 |
| `goalZoneHorizontalExpansion` | `targetZoneHorizontalExpansion` | 0.01 | 目标区域水平扩展 |
| `interactionDistanceThreshold` | `interactionDistanceThreshold` | 0.20 | 交互距离阈值 |
| `rimExpansionFactor` | `expansionFactor` | 0.10 | 扩展区域系数 |
| `closeProximityThreshold` | `closeProximityThreshold` | 0.15 | 近距离阈值 |

**差异说明：**
- 命名不同：`goal`/`rim` → `target`（更通用）
- 参数值完全一致

### 6. 标签配置

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| - | `targetLabels` | ["rim", "1", "hoop", "basket", "class_1"] | 目标标签 |
| - | `objectLabels` | ["ball", "0", "basketball", "sport ball", "class_0"] | 对象标签 |

**差异说明：**
- HighlightMoment 在代码中硬编码标签
- SDK 将标签作为可配置参数，更灵活

### 7. 剪辑参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `clipLeadTime` | `clipConfig.leadTime` | 4.0s | 剪辑前置时间 |
| `clipTrailTime` | `clipConfig.trailTime` | 2.0s | 剪辑后置时间 |
| `maxConcurrentExports` | `clipConfig.maxConcurrentExports` | 2 | 最大并发剪辑数 |
| `exportTimeout` | `clipConfig.exportTimeout` | 120s | 剪辑超时时间 |
| - | `clipConfig.outputDirectory` | nil | 输出目录 |
| - | `clipConfig.sessionName` | nil | 会话名称 |

**差异说明：**
- SDK 将剪辑参数独立为 `VideoClipConfig`
- SDK 增加了输出目录和会话名称配置

### 8. 调试参数

| HighlightMoment | VideoAnalysisSDK | 默认值 | 说明 |
|----------------|------------------|--------|------|
| `debugMode` | `debugMode` | false (SDK) / true (HM) | 调试模式 |
| `maxLogCount` | `maxLogCount` | 1000 | 最大日志数 |

**差异说明：**
- SDK 默认关闭调试模式（生产环境友好）
- HighlightMoment 默认开启调试模式（开发环境友好）

## 核心差异总结

### 1. 架构差异

**HighlightMoment:**
```swift
struct DetectorConfig {
    // 所有参数在一个结构体中
    var confThresRim: Float
    var confThresBall: Float
    var frameSkip: Int
    // ... 其他参数
}
```

**VideoAnalysisSDK:**
```swift
struct InferenceConfig {
    var confidenceThreshold: Float
    var nmsThreshold: Float
    // ... 推理相关参数
}

struct VideoAnalysisConfig {
    var inferenceConfig: InferenceConfig
    var frameSkip: Int
    // ... 分析相关参数
}

struct VideoClipConfig {
    var leadTime: TimeInterval
    // ... 剪辑相关参数
}
```

### 2. 命名差异

| 概念 | HighlightMoment | VideoAnalysisSDK |
|------|----------------|------------------|
| 进球/事件 | shot | event |
| 篮筐/目标 | rim/goal | target |
| 篮球/对象 | ball | object |

### 3. 扩展性差异

**HighlightMoment:**
- 专注于篮球场景
- 参数名称具体明确
- 适合单一应用场景

**VideoAnalysisSDK:**
- 设计为通用框架
- 参数名称抽象通用
- 易于扩展到其他运动场景（足球、网球等）

## 迁移建议

### 从 HighlightMoment 迁移到 SDK

```swift
// HighlightMoment 配置
let hmConfig = DetectorConfig.default

// 转换为 SDK 配置
let inferenceConfig = InferenceConfig(
    confidenceThreshold: hmConfig.confThresRim,  // 或 confThresBall
    nmsThreshold: 0.45,
    maxDetections: 100
)

let sdkConfig = VideoAnalysisConfig(
    inferenceConfig: inferenceConfig,
    frameSkip: hmConfig.frameSkip,
    calibrationFrames: hmConfig.calibrationFrames,
    startTime: hmConfig.startTime,
    endTime: hmConfig.endTime,
    eventWindow: hmConfig.shotWindow,
    eventCooldown: hmConfig.shotCooldown,
    minInteractionInterval: hmConfig.minInteractionInterval,
    targetZoneHeight: hmConfig.goalZoneHeight,
    targetZoneHorizontalExpansion: hmConfig.goalZoneHorizontalExpansion,
    interactionDistanceThreshold: hmConfig.interactionDistanceThreshold,
    expansionFactor: hmConfig.rimExpansionFactor,
    closeProximityThreshold: hmConfig.closeProximityThreshold,
    debugMode: hmConfig.debugMode,
    maxLogCount: hmConfig.maxLogCount
)

let clipConfig = VideoClipConfig(
    leadTime: hmConfig.clipLeadTime,
    trailTime: hmConfig.clipTrailTime,
    maxConcurrentExports: hmConfig.maxConcurrentExports,
    exportTimeout: hmConfig.exportTimeout
)
```

### 简化迁移（使用默认值）

```swift
// 如果 HighlightMoment 使用默认配置
let hmConfig = DetectorConfig.default

// SDK 也使用默认配置（参数值完全一致）
let sdkConfig = VideoAnalysisConfig.default
let clipConfig = VideoClipConfig.default

// 只需修改特定参数
var customConfig = VideoAnalysisConfig.default
customConfig.debugMode = hmConfig.debugMode
customConfig.startTime = hmConfig.startTime
```

## 推荐做法

### 对于 HighlightMoment 项目
1. 保持当前的 `DetectorConfig` 结构（面向应用）
2. 在调用 SDK 时进行参数转换
3. 可以创建一个扩展方法简化转换：

```swift
extension DetectorConfig {
    func toSDKConfig() -> (VideoAnalysisConfig, VideoClipConfig) {
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: self.confThresRim
        )
        
        let analysisConfig = VideoAnalysisConfig(
            inferenceConfig: inferenceConfig,
            frameSkip: self.frameSkip,
            // ... 其他参数映射
        )
        
        let clipConfig = VideoClipConfig(
            leadTime: self.clipLeadTime,
            trailTime: self.clipTrailTime
        )
        
        return (analysisConfig, clipConfig)
    }
}
```

### 对于新项目
1. 直接使用 SDK 的配置结构
2. 利用默认配置快速开始
3. 根据需要进行参数调整

## 总结

两个配置系统的**核心参数值完全一致**，主要差异在于：

1. **结构组织** - SDK 采用分层设计，更模块化
2. **命名风格** - SDK 使用更通用的术语
3. **扩展性** - SDK 设计为通用框架，易于扩展
4. **默认值** - 除了 `debugMode`，其他默认值完全相同

这种设计既保证了 HighlightMoment 的业务逻辑不变，又让 SDK 具有更好的通用性和可维护性。
