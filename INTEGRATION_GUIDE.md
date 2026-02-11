# VideoAnalysisSDK 集成指南

## 目录

1. [快速开始](#快速开始)
2. [安装配置](#安装配置)
3. [核心概念](#核心概念)
4. [API 参考](#api-参考)
5. [配置详解](#配置详解)
6. [回调说明](#回调说明)
7. [完整示例](#完整示例)
8. [最佳实践](#最佳实践)
9. [常见问题](#常见问题)

---

## 快速开始

### 最简单的使用方式

```swift
import VideoAnalysisSDK

// 1. 准备文件路径
let videoURL = URL(fileURLWithPath: "/path/to/video.mp4")
let modelURL = URL(fileURLWithPath: "/path/to/model.mlmodelc")

// 2. 创建分析服务（使用默认配置）
let service = try VideoAnalysisSDK.createVideoAnalysisService(
    modelURL: modelURL,
    config: .default,
    clipConfig: .default
)

// 3. 配置回调
let callbacks = VideoAnalysisCallbacks(
    onLog: { log in print(log) },
    onProgress: { progress in print("进度: \(Int(progress * 100))%") },
    onEvent: { event in print("检测到事件: \(event)") },
    onClipCreated: { clip in print("剪辑创建: \(clip.url)") },
    onCompletion: { result in print("完成! 处理了 \(result.totalFrames) 帧") },
    onError: { error in print("错误: \(error)") }
)

// 4. 开始分析
service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
```

---

## 安装配置

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/VideoAnalysisSDK.git", from: "1.0.0")
]
```

### 手动集成

1. 将 `VideoAnalysisSDK` 文件夹拖入项目
2. 确保 `Build Phases` → `Link Binary With Libraries` 包含：
   - CoreML.framework
   - AVFoundation.framework
   - CoreVideo.framework
   - CoreGraphics.framework

### 系统要求

- iOS 14.0+ / macOS 11.0+
- Xcode 13.0+
- Swift 5.5+

---

## 核心概念

### 1. 分析流程

```
视频输入 → 帧提取 → 目标校准 → 事件检测 → 视频剪辑 → 结果输出
```

### 2. 三大配置

- **InferenceConfig**: 推理配置（模型检测参数）
- **VideoAnalysisConfig**: 分析配置（事件检测逻辑）
- **VideoClipConfig**: 剪辑配置（视频导出参数）

### 3. 事件类型

```swift
public enum AnalysisEvent {
    case calibrating(currentSamples: Int, targetSamples: Int)  // 校准中
    case calibrated(box: CGRect)                                // 校准完成
    case eventDetected(timestamp: TimeInterval, metadata: [String: Any]?)  // 事件检测
    case custom(name: String, metadata: [String: Any]?)        // 自定义事件
}
```

---

## API 参考

### 主入口

#### createVideoAnalysisService

创建视频分析服务实例。

```swift
public static func createVideoAnalysisService(
    modelURL: URL,
    config: VideoAnalysisConfig = .default,
    clipConfig: VideoClipConfig? = nil
) throws -> VideoAnalysisServiceProtocol
```

**参数：**
- `modelURL`: CoreML 模型文件路径（支持 .mlmodelc 和 .mlpackage）
- `config`: 视频分析配置（可选，默认使用 `.default`）
- `clipConfig`: 视频剪辑配置（可选，不传则不生成剪辑）

**返回值：**
- `VideoAnalysisServiceProtocol`: 分析服务实例

**异常：**
- `VideoAnalysisError.modelNotFound`: 模型文件不存在
- `VideoAnalysisError.modelLoadFailed`: 模型加载失败

**示例：**
```swift
// 基础用法
let service = try VideoAnalysisSDK.createVideoAnalysisService(
    modelURL: modelURL
)

// 带自定义配置
let service = try VideoAnalysisSDK.createVideoAnalysisService(
    modelURL: modelURL,
    config: .highPrecision,
    clipConfig: VideoClipConfig(outputDirectory: outputDir)
)
```

---

### VideoAnalysisServiceProtocol

视频分析服务协议，定义了核心操作方法。

#### startAnalysis

开始视频分析。

```swift
func startAnalysis(videoURL: URL, callbacks: VideoAnalysisCallbacks)
```

**参数：**
- `videoURL`: 视频文件路径
- `callbacks`: 回调接口

**示例：**
```swift
service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
```

#### stop

停止分析。

```swift
func stop()
```

**示例：**
```swift
service.stop()
```

#### pause

暂停分析。

```swift
func pause()
```

**示例：**
```swift
service.pause()
```

#### resume

恢复分析。

```swift
func resume()
```

**示例：**
```swift
service.resume()
```

#### 状态属性

```swift
var isRunning: Bool { get }  // 是否正在运行
var isPaused: Bool { get }   // 是否已暂停
```

---

## 配置详解

### InferenceConfig（推理配置）

控制 CoreML 模型的推理行为。

```swift
public struct InferenceConfig {
    public var confidenceThreshold: Float        // 置信度阈值
    public var nmsThreshold: Float               // NMS 阈值
    public var maxDetections: Int                // 最大检测数
    public var enableMemoryOptimization: Bool    // 内存优化
    public var labelFilter: Set<String>?         // 标签过滤
}
```

#### 参数说明

| 参数 | 类型 | 默认值 | 范围 | 说明 |
|------|------|--------|------|------|
| `confidenceThreshold` | Float | 0.15 | 0.0 - 1.0 | 检测置信度阈值，越高越严格 |
| `nmsThreshold` | Float | 0.45 | 0.0 - 1.0 | 非极大值抑制阈值，用于去除重复检测 |
| `maxDetections` | Int | 100 | 1 - 1000 | 单帧最大检测对象数 |
| `enableMemoryOptimization` | Bool | true | - | 是否启用内存优化 |
| `labelFilter` | Set<String>? | nil | - | 只保留指定标签的检测结果 |

#### 预设配置

```swift
// 默认配置（平衡）
InferenceConfig.default

// 高精度（更严格）
InferenceConfig.highPrecision
// confidenceThreshold: 0.5, nmsThreshold: 0.3

// 高召回率（更宽松）
InferenceConfig.highRecall
// confidenceThreshold: 0.1, nmsThreshold: 0.6

// 高性能（更快）
InferenceConfig.performance
// confidenceThreshold: 0.2, maxDetections: 50
```

#### 使用示例

```swift
// 使用默认配置
let config = InferenceConfig.default

// 自定义配置
let config = InferenceConfig(
    confidenceThreshold: 0.2,
    nmsThreshold: 0.5,
    maxDetections: 50,
    enableMemoryOptimization: true,
    labelFilter: ["ball", "rim"]  // 只检测球和篮筐
)

// 基于预设修改
var config = InferenceConfig.highPrecision
config.maxDetections = 80
```

#### 调优建议

**提高准确度：**
- 增加 `confidenceThreshold` (0.3 - 0.5)
- 减小 `nmsThreshold` (0.2 - 0.3)

**提高召回率：**
- 减小 `confidenceThreshold` (0.1 - 0.15)
- 增加 `nmsThreshold` (0.5 - 0.7)

**提高性能：**
- 减少 `maxDetections` (30 - 50)
- 增加 `confidenceThreshold` (0.25 - 0.3)

---

### VideoAnalysisConfig（分析配置）

控制视频分析和事件检测的核心逻辑。

```swift
public struct VideoAnalysisConfig {
    // 推理配置
    public var inferenceConfig: InferenceConfig
    
    // 性能参数
    public var frameSkip: Int
    public var calibrationFrames: Int
    
    // 时间范围
    public var startTime: TimeInterval?
    public var endTime: TimeInterval?
    
    // 事件检测
    public var eventWindow: TimeInterval
    public var eventCooldown: TimeInterval
    public var minInteractionInterval: TimeInterval
    
    // 空间判定
    public var targetZoneHeight: CGFloat
    public var targetZoneHorizontalExpansion: CGFloat
    public var interactionDistanceThreshold: CGFloat
    public var expansionFactor: CGFloat
    public var closeProximityThreshold: CGFloat
    
    // 标签配置
    public var targetLabels: Set<String>
    public var objectLabels: Set<String>
    
    // 调试
    public var debugMode: Bool
    public var maxLogCount: Int
}
```

#### 参数详解

##### 性能参数

| 参数 | 类型 | 默认值 | 范围 | 说明 |
|------|------|--------|------|------|
| `frameSkip` | Int | 3 | 1 - 10 | 跳帧数，每 N 帧处理一次。值越大速度越快但可能漏检 |
| `calibrationFrames` | Int | 30 | 10 - 100 | 校准所需帧数。值越大越稳定但启动越慢 |

**示例：**
```swift
// 高性能（快速处理）
config.frameSkip = 5
config.calibrationFrames = 20

// 高精度（详细分析）
config.frameSkip = 2
config.calibrationFrames = 40
```

##### 时间范围参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `startTime` | TimeInterval? | nil | 开始时间（秒），nil 表示从头开始 |
| `endTime` | TimeInterval? | nil | 结束时间（秒），nil 表示到视频结束 |

**示例：**
```swift
// 分析整个视频
config.startTime = nil
config.endTime = nil

// 只分析 5:00 到 10:00
config.startTime = 300  // 5分钟
config.endTime = 600    // 10分钟

// 从 2:00 开始到结束
config.startTime = 120
config.endTime = nil
```

##### 事件检测参数

| 参数 | 类型 | 默认值 | 范围 | 说明 |
|------|------|--------|------|------|
| `eventWindow` | TimeInterval | 2.5 | 0.5 - 10.0 | 事件时间窗口（秒）。交互后在此时间内进入目标区域才算事件 |
| `eventCooldown` | TimeInterval | 3.0 | 1.0 - 10.0 | 事件冷却时间（秒）。两次事件之间的最小间隔 |
| `minInteractionInterval` | TimeInterval | 0.05 | 0.0 - 1.0 | 最小交互间隔（秒）。避免瞬时判定 |

**示例：**
```swift
// 宽松检测（容易触发）
config.eventWindow = 3.5
config.eventCooldown = 2.0
config.minInteractionInterval = 0.0

// 严格检测（减少误判）
config.eventWindow = 2.0
config.eventCooldown = 5.0
config.minInteractionInterval = 0.1
```

**时序图：**
```
时间轴: ----[交互]----[进入目标区]----[下次事件]----
         ↑           ↑              ↑
         |           |              |
         |    eventWindow (2.5s)    |
         |                          |
         |---- eventCooldown (3.0s) ----|
```

##### 空间判定参数

所有空间参数使用归一化坐标（0.0 - 1.0）。

| 参数 | 类型 | 默认值 | 范围 | 说明 |
|------|------|--------|------|------|
| `targetZoneHeight` | CGFloat | 0.06 | 0.01 - 0.20 | 目标区域高度（篮筐下方的判定区域） |
| `targetZoneHorizontalExpansion` | CGFloat | 0.01 | 0.0 - 0.05 | 目标区域左右扩展 |
| `interactionDistanceThreshold` | CGFloat | 0.20 | 0.05 - 0.50 | 交互距离阈值（对象到目标中心的距离） |
| `expansionFactor` | CGFloat | 0.10 | 0.0 - 0.30 | 目标扩展区域系数 |
| `closeProximityThreshold` | CGFloat | 0.15 | 0.05 - 0.30 | 近距离判定阈值 |

**空间示意图：**
```
        [篮筐/目标]
    ┌─────────────────┐
    │                 │ ← expansionFactor (扩展区域)
    │   ┌─────────┐   │
    │   │  目标   │   │
    │   └─────────┘   │
    │        ↓        │
    │   ┌─────────┐   │
    │   │目标区域 │   │ ← targetZoneHeight
    │   └─────────┘   │
    └─────────────────┘
    ↑                 ↑
    targetZoneHorizontalExpansion
```

**示例：**
```swift
// 宽松判定（大区域）
config.targetZoneHeight = 0.10
config.targetZoneHorizontalExpansion = 0.03
config.interactionDistanceThreshold = 0.30
config.expansionFactor = 0.15

// 严格判定（小区域）
config.targetZoneHeight = 0.04
config.targetZoneHorizontalExpansion = 0.0
config.interactionDistanceThreshold = 0.15
config.expansionFactor = 0.05
```

##### 标签配置

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `targetLabels` | Set<String> | ["rim", "1", "hoop", "basket", "class_1"] | 目标标签（篮筐、球门等） |
| `objectLabels` | Set<String> | ["ball", "0", "basketball", "sport ball", "class_0"] | 对象标签（球类等） |

**示例：**
```swift
// 篮球场景
config.targetLabels = ["rim", "hoop", "basket"]
config.objectLabels = ["ball", "basketball"]

// 足球场景
config.targetLabels = ["goal", "goalpost"]
config.objectLabels = ["soccer ball", "football"]

// 支持多种标签格式
config.targetLabels = ["rim", "1", "class_1"]  // 支持数字和类名
```

##### 调试参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `debugMode` | Bool | false | 是否输出详细日志 |
| `maxLogCount` | Int | 1000 | 内存中保存的最大日志数 |

**示例：**
```swift
// 开发环境
config.debugMode = true
config.maxLogCount = 2000

// 生产环境
config.debugMode = false
config.maxLogCount = 500
```

#### 预设配置

```swift
// 默认配置（推荐）
VideoAnalysisConfig.default

// 高性能配置
VideoAnalysisConfig.performance
// frameSkip: 5, calibrationFrames: 20

// 高精度配置
VideoAnalysisConfig.highPrecision
// frameSkip: 2, calibrationFrames: 40, 更严格的阈值
```

#### 完整示例

```swift
// 方式1: 使用默认配置
let config = VideoAnalysisConfig.default

// 方式2: 基于默认配置修改
var config = VideoAnalysisConfig.default
config.debugMode = true
config.startTime = 300
config.endTime = 600

// 方式3: 完全自定义
let config = VideoAnalysisConfig(
    inferenceConfig: InferenceConfig(
        confidenceThreshold: 0.2,
        nmsThreshold: 0.5
    ),
    frameSkip: 3,
    calibrationFrames: 30,
    startTime: nil,
    endTime: nil,
    eventWindow: 2.5,
    eventCooldown: 3.0,
    minInteractionInterval: 0.05,
    targetZoneHeight: 0.06,
    targetZoneHorizontalExpansion: 0.01,
    interactionDistanceThreshold: 0.20,
    expansionFactor: 0.10,
    closeProximityThreshold: 0.15,
    targetLabels: ["rim", "hoop"],
    objectLabels: ["ball", "basketball"],
    debugMode: true,
    maxLogCount: 1000
)
```

---

### VideoClipConfig（剪辑配置）

控制视频剪辑和导出行为。

```swift
public struct VideoClipConfig {
    public var leadTime: TimeInterval           // 前置时间
    public var trailTime: TimeInterval          // 后置时间
    public var maxConcurrentExports: Int        // 最大并发数
    public var exportTimeout: TimeInterval      // 超时时间
    public var outputDirectory: URL?            // 输出目录
    public var sessionName: String?             // 会话名称
}
```

#### 参数说明

| 参数 | 类型 | 默认值 | 范围 | 说明 |
|------|------|--------|------|------|
| `leadTime` | TimeInterval | 4.0 | 0.0 - 10.0 | 事件前多少秒开始剪辑 |
| `trailTime` | TimeInterval | 2.0 | 0.0 - 10.0 | 事件后多少秒结束剪辑 |
| `maxConcurrentExports` | Int | 2 | 1 - 8 | 同时进行的剪辑任务数 |
| `exportTimeout` | TimeInterval | 120 | 30 - 300 | 单个剪辑任务超时时间（秒） |
| `outputDirectory` | URL? | nil | - | 输出目录，nil 使用临时目录 |
| `sessionName` | String? | nil | - | 会话名称，用于创建子文件夹 |

#### 剪辑时长计算

```
剪辑总时长 = leadTime + trailTime
```

**示例：**
```
事件时间: 10:00 (600秒)
leadTime: 4秒
trailTime: 2秒

剪辑范围: 9:56 - 10:02 (596秒 - 602秒)
剪辑时长: 6秒
```

#### 使用示例

```swift
// 使用默认配置
let config = VideoClipConfig.default

// 自定义配置
let config = VideoClipConfig(
    leadTime: 5.0,
    trailTime: 3.0,
    maxConcurrentExports: 3,
    exportTimeout: 180,
    outputDirectory: URL(fileURLWithPath: "~/Desktop/Clips"),
    sessionName: "Game_2024_01_15"
)

// 不生成剪辑（只检测事件）
let config: VideoClipConfig? = nil
```

#### 输出路径结构

```
outputDirectory/
└── sessionName/
    ├── clip_001_0600.00s.mp4
    ├── clip_002_1200.50s.mp4
    └── clip_003_1800.25s.mp4
```

**文件命名规则：**
- `clip_XXX_TTTT.TTs.mp4`
- `XXX`: 剪辑序号（001, 002, ...）
- `TTTT.TT`: 事件时间戳（秒）

#### 性能建议

**高性能设备：**
```swift
config.maxConcurrentExports = 4
config.exportTimeout = 90
```

**低性能设备：**
```swift
config.maxConcurrentExports = 1
config.exportTimeout = 180
```

**长视频：**
```swift
config.maxConcurrentExports = 2
config.exportTimeout = 240
```

---

## 回调说明

### VideoAnalysisCallbacks

所有回调都是可选的，只需实现需要的回调。

```swift
public struct VideoAnalysisCallbacks {
    public var onLog: ((String) -> Void)?
    public var onProgress: ((Double) -> Void)?
    public var onEvent: ((AnalysisEvent) -> Void)?
    public var onClipCreated: ((ClipResult) -> Void)?
    public var onCompletion: ((AnalysisResult) -> Void)?
    public var onError: ((Error) -> Void)?
}
```

### 回调详解

#### onLog

日志回调，用于输出分析过程中的详细信息。

```swift
onLog: { log in
    print(log)
    // 或保存到文件
    // logFile.append(log)
}
```

**日志示例：**
```
🎬 开始视频分析
📹 视频文件: basketball.mp4
✅ 视频加载成功
🎯 开始校准...
🟢 校准进度: 10/30 (33%)
✅ 校准完成！
🔍 开始事件检测...
📊 [时间 10:00 | 600.00s]
   检测到: 篮筐×1, 篮球×1
⚡ 交互检测: 距离=0.15 < 阈值=0.20
🎯 对象进入目标区域
🎉 ✅ 进球判定成功！
```

#### onProgress

进度回调，返回 0.0 - 1.0 的进度值。

```swift
onProgress: { progress in
    let percentage = Int(progress * 100)
    print("进度: \(percentage)%")
    
    // 更新 UI
    DispatchQueue.main.async {
        progressBar.progress = Float(progress)
        progressLabel.text = "\(percentage)%"
    }
}
```

**进度计算：**
- 0.0 - 0.05: 初始化和加载
- 0.05 - 0.95: 视频分析（按帧数比例）
- 0.95 - 1.0: 完成和清理

#### onEvent

事件回调，接收分析过程中的各种事件。

```swift
onEvent: { event in
    switch event {
    case .calibrating(let current, let target):
        print("校准中: \(current)/\(target)")
        
    case .calibrated(let box):
        print("校准完成: 位置=(\(box.origin.x), \(box.origin.y))")
        
    case .eventDetected(let timestamp, let metadata):
        print("检测到事件: \(timestamp)秒")
        // 记录事件
        events.append(timestamp)
        
    case .custom(let name, let metadata):
        print("自定义事件: \(name)")
    }
}
```

**事件类型：**

1. **calibrating**: 校准进行中
   ```swift
   case .calibrating(currentSamples: 15, targetSamples: 30)
   ```

2. **calibrated**: 校准完成
   ```swift
   case .calibrated(box: CGRect(x: 0.5, y: 0.9, width: 0.1, height: 0.05))
   ```

3. **eventDetected**: 检测到事件（进球等）
   ```swift
   case .eventDetected(timestamp: 600.5, metadata: nil)
   ```

4. **custom**: 自定义事件
   ```swift
   case .custom(name: "特殊情况", metadata: ["reason": "..."])
   ```

#### onClipCreated

剪辑创建回调，在每个剪辑生成后调用。

```swift
onClipCreated: { clip in
    print("剪辑创建成功:")
    print("  文件: \(clip.url.lastPathComponent)")
    print("  路径: \(clip.url.path)")
    print("  时长: \(clip.duration)秒")
    print("  大小: \(clip.fileSize / 1024 / 1024)MB")
    
    // 保存到数据库
    database.saveClip(clip)
    
    // 更新 UI
    DispatchQueue.main.async {
        clipList.append(clip)
        tableView.reloadData()
    }
}
```

**ClipResult 结构：**
```swift
public struct ClipResult {
    public let url: URL              // 文件路径
    public let timestamp: TimeInterval  // 事件时间戳
    public let duration: TimeInterval   // 剪辑时长
    public let fileSize: Int64          // 文件大小（字节）
}
```

#### onCompletion

完成回调，在整个分析流程结束后调用。

```swift
onCompletion: { result in
    print("分析完成!")
    print("  处理帧数: \(result.totalFrames)")
    print("  处理时长: \(result.duration)秒")
    print("  平均FPS: \(result.averageFPS)")
    print("  检测事件: \(result.events.count)个")
    
    // 显示总结
    showSummary(result)
}
```

**AnalysisResult 结构：**
```swift
public struct AnalysisResult {
    public let events: [AnalysisEvent]  // 所有事件
    public let totalFrames: Int         // 处理的总帧数
    public let duration: TimeInterval   // 处理耗时
    
    public var averageFPS: Double {     // 平均处理速度
        return Double(totalFrames) / duration
    }
}
```

#### onError

错误回调，在发生错误时调用。

```swift
onError: { error in
    print("错误: \(error.localizedDescription)")
    
    // 根据错误类型处理
    if let analysisError = error as? VideoAnalysisError {
        switch analysisError {
        case .videoLoadFailed(let reason):
            showAlert("视频加载失败: \(reason)")
        case .modelNotFound(let path):
            showAlert("模型文件不存在: \(path)")
        case .modelLoadFailed(let reason):
            showAlert("模型加载失败: \(reason)")
        default:
            showAlert("分析失败: \(error.localizedDescription)")
        }
    }
}
```

**错误类型：**
```swift
public enum VideoAnalysisError: Error {
    case videoLoadFailed(String)        // 视频加载失败
    case modelNotFound(String)          // 模型文件不存在
    case modelLoadFailed(String)        // 模型加载失败
    case readerCreationFailed(String)   // 读取器创建失败
    case invalidTimeRange               // 无效的时间范围
    case clipExportFailed(String)       // 剪辑导出失败
    case unknown(String)                // 未知错误
}
```

### 完整回调示例

```swift
let callbacks = VideoAnalysisCallbacks(
    onLog: { log in
        print(log)
    },
    
    onProgress: { progress in
        DispatchQueue.main.async {
            self.progressBar.progress = Float(progress)
        }
    },
    
    onEvent: { event in
        switch event {
        case .calibrating(let current, let target):
            print("校准: \(current)/\(target)")
            
        case .calibrated:
            print("校准完成，开始检测")
            
        case .eventDetected(let timestamp, _):
            print("检测到进球: \(timestamp)秒")
            self.goalTimestamps.append(timestamp)
            
        case .custom(let name, _):
            print("自定义事件: \(name)")
        }
    },
    
    onClipCreated: { clip in
        print("剪辑创建: \(clip.url.lastPathComponent)")
        DispatchQueue.main.async {
            self.clips.append(clip)
            self.tableView.reloadData()
        }
    },
    
    onCompletion: { result in
        print("完成! 处理了 \(result.totalFrames) 帧")
        print("平均速度: \(String(format: "%.2f", result.averageFPS)) FPS")
        DispatchQueue.main.async {
            self.showCompletionAlert(result)
        }
    },
    
    onError: { error in
        print("错误: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.showErrorAlert(error)
        }
    }
)
```

### 线程安全

**重要提示：** 所有回调都在主线程执行，可以直接更新 UI。

```swift
onProgress: { progress in
    // 直接更新 UI，无需 DispatchQueue.main.async
    self.progressBar.progress = Float(progress)
}
```

如果需要在后台线程执行耗时操作：

```swift
onClipCreated: { clip in
    // 后台处理
    DispatchQueue.global().async {
        self.processClip(clip)
    }
}
```

---

## 完整示例

### 示例 1: 基础使用

最简单的集成方式，使用默认配置。

```swift
import VideoAnalysisSDK

class VideoAnalyzer {
    var service: VideoAnalysisServiceProtocol?
    
    func analyzeVideo(videoPath: String, modelPath: String) {
        let videoURL = URL(fileURLWithPath: videoPath)
        let modelURL = URL(fileURLWithPath: modelPath)
        
        do {
            // 创建服务
            service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelURL: modelURL,
                config: .default,
                clipConfig: .default
            )
            
            // 配置回调
            let callbacks = VideoAnalysisCallbacks(
                onLog: { print($0) },
                onProgress: { print("进度: \(Int($0 * 100))%") },
                onEvent: { event in
                    if case .eventDetected(let timestamp, _) = event {
                        print("检测到进球: \(timestamp)秒")
                    }
                },
                onCompletion: { result in
                    print("完成! 处理了 \(result.totalFrames) 帧")
                },
                onError: { error in
                    print("错误: \(error.localizedDescription)")
                }
            )
            
            // 开始分析
            service?.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("初始化失败: \(error)")
        }
    }
    
    func stop() {
        service?.stop()
    }
}
```

### 示例 2: SwiftUI 集成

在 SwiftUI 应用中使用 SDK。

```swift
import SwiftUI
import VideoAnalysisSDK

class AnalysisViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isAnalyzing = false
    @Published var logs: [String] = []
    @Published var clips: [ClipResult] = []
    @Published var errorMessage: String?
    
    private var service: VideoAnalysisServiceProtocol?
    
    func startAnalysis(videoURL: URL, modelURL: URL) {
        isAnalyzing = true
        progress = 0.0
        logs = []
        clips = []
        errorMessage = nil
        
        do {
            // 自定义配置
            var config = VideoAnalysisConfig.default
            config.debugMode = true
            
            let clipConfig = VideoClipConfig(
                outputDirectory: FileManager.default.temporaryDirectory
            )
            
            service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelURL: modelURL,
                config: config,
                clipConfig: clipConfig
            )
            
            let callbacks = VideoAnalysisCallbacks(
                onLog: { [weak self] log in
                    DispatchQueue.main.async {
                        self?.logs.append(log)
                    }
                },
                onProgress: { [weak self] progress in
                    DispatchQueue.main.async {
                        self?.progress = progress
                    }
                },
                onEvent: { [weak self] event in
                    if case .eventDetected(let timestamp, _) = event {
                        DispatchQueue.main.async {
                            self?.logs.append("🎯 检测到进球: \(timestamp)秒")
                        }
                    }
                },
                onClipCreated: { [weak self] clip in
                    DispatchQueue.main.async {
                        self?.clips.append(clip)
                    }
                },
                onCompletion: { [weak self] result in
                    DispatchQueue.main.async {
                        self?.isAnalyzing = false
                        self?.logs.append("✅ 完成! 处理了 \(result.totalFrames) 帧")
                    }
                },
                onError: { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isAnalyzing = false
                        self?.errorMessage = error.localizedDescription
                    }
                }
            )
            
            service?.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            isAnalyzing = false
            errorMessage = error.localizedDescription
        }
    }
    
    func stop() {
        service?.stop()
        isAnalyzing = false
    }
}

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isAnalyzing {
                ProgressView(value: viewModel.progress) {
                    Text("分析中: \(Int(viewModel.progress * 100))%")
                }
                .padding()
                
                Button("停止") {
                    viewModel.stop()
                }
            }
            
            List {
                Section("日志") {
                    ForEach(viewModel.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                
                Section("剪辑 (\(viewModel.clips.count))") {
                    ForEach(viewModel.clips, id: \.url) { clip in
                        VStack(alignment: .leading) {
                            Text(clip.url.lastPathComponent)
                            Text("时长: \(String(format: "%.2f", clip.duration))秒")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

### 示例 3: 高级配置

完全自定义配置，适用于特殊场景。

```swift
import VideoAnalysisSDK

class AdvancedAnalyzer {
    func analyzeWithCustomConfig(videoURL: URL, modelURL: URL) throws {
        // 1. 自定义推理配置
        let inferenceConfig = InferenceConfig(
            confidenceThreshold: 0.2,
            nmsThreshold: 0.5,
            maxDetections: 50,
            enableMemoryOptimization: true,
            labelFilter: ["ball", "rim"]  // 只检测球和篮筐
        )
        
        // 2. 自定义分析配置
        let analysisConfig = VideoAnalysisConfig(
            inferenceConfig: inferenceConfig,
            frameSkip: 2,                    // 更密集的采样
            calibrationFrames: 40,           // 更稳定的校准
            startTime: 300,                  // 从5分钟开始
            endTime: 900,                    // 到15分钟结束
            eventWindow: 3.0,                // 更宽松的时间窗口
            eventCooldown: 2.5,              // 更短的冷却时间
            minInteractionInterval: 0.0,     // 允许瞬时判定
            targetZoneHeight: 0.08,          // 更大的目标区域
            targetZoneHorizontalExpansion: 0.02,
            interactionDistanceThreshold: 0.25,
            expansionFactor: 0.12,
            closeProximityThreshold: 0.18,
            targetLabels: ["rim", "hoop", "basket", "1"],
            objectLabels: ["ball", "basketball", "0"],
            debugMode: true,
            maxLogCount: 2000
        )
        
        // 3. 自定义剪辑配置
        let clipConfig = VideoClipConfig(
            leadTime: 5.0,                   // 前置5秒
            trailTime: 3.0,                  // 后置3秒
            maxConcurrentExports: 3,         // 3个并发任务
            exportTimeout: 180,              // 3分钟超时
            outputDirectory: URL(fileURLWithPath: "~/Desktop/Highlights"),
            sessionName: "Game_\(Date().timeIntervalSince1970)"
        )
        
        // 4. 创建服务
        let service = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: analysisConfig,
            clipConfig: clipConfig
        )
        
        // 5. 详细的回调处理
        var eventTimestamps: [TimeInterval] = []
        var clipURLs: [URL] = []
        
        let callbacks = VideoAnalysisCallbacks(
            onLog: { log in
                // 保存到文件
                if let data = (log + "\n").data(using: .utf8) {
                    let logFile = URL(fileURLWithPath: "~/Desktop/analysis.log")
                    try? data.append(to: logFile)
                }
            },
            
            onProgress: { progress in
                // 更新进度条和预估剩余时间
                let percentage = Int(progress * 100)
                print("进度: \(percentage)%")
            },
            
            onEvent: { event in
                switch event {
                case .calibrating(let current, let target):
                    let progress = Double(current) / Double(target) * 100
                    print("校准进度: \(String(format: "%.0f", progress))%")
                    
                case .calibrated(let box):
                    print("校准完成:")
                    print("  位置: (\(box.origin.x), \(box.origin.y))")
                    print("  大小: \(box.size.width) x \(box.size.height)")
                    
                case .eventDetected(let timestamp, let metadata):
                    eventTimestamps.append(timestamp)
                    let minutes = Int(timestamp) / 60
                    let seconds = Int(timestamp) % 60
                    print("进球 #\(eventTimestamps.count): \(minutes):\(String(format: "%02d", seconds))")
                    
                    // 发送通知
                    NotificationCenter.default.post(
                        name: .goalDetected,
                        object: nil,
                        userInfo: ["timestamp": timestamp]
                    )
                    
                case .custom(let name, let metadata):
                    print("自定义事件: \(name)")
                    if let metadata = metadata {
                        print("  详情: \(metadata)")
                    }
                }
            },
            
            onClipCreated: { clip in
                clipURLs.append(clip.url)
                print("剪辑 #\(clipURLs.count) 创建成功:")
                print("  文件: \(clip.url.lastPathComponent)")
                print("  大小: \(String(format: "%.2f", Double(clip.fileSize) / 1024 / 1024))MB")
                
                // 生成缩略图
                generateThumbnail(for: clip.url)
            },
            
            onCompletion: { result in
                print("\n分析完成!")
                print("统计信息:")
                print("  处理帧数: \(result.totalFrames)")
                print("  处理时长: \(String(format: "%.2f", result.duration))秒")
                print("  平均FPS: \(String(format: "%.2f", result.averageFPS))")
                print("  检测进球: \(eventTimestamps.count)个")
                print("  生成剪辑: \(clipURLs.count)个")
                
                // 生成报告
                generateReport(
                    events: eventTimestamps,
                    clips: clipURLs,
                    result: result
                )
            },
            
            onError: { error in
                print("错误: \(error.localizedDescription)")
                
                // 错误恢复
                if let analysisError = error as? VideoAnalysisError {
                    handleAnalysisError(analysisError)
                }
            }
        )
        
        // 6. 开始分析
        service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    }
    
    private func generateThumbnail(for url: URL) {
        // 生成缩略图的实现
    }
    
    private func generateReport(events: [TimeInterval], clips: [URL], result: AnalysisResult) {
        // 生成分析报告的实现
    }
    
    private func handleAnalysisError(_ error: VideoAnalysisError) {
        // 错误处理的实现
    }
}

extension Notification.Name {
    static let goalDetected = Notification.Name("goalDetected")
}

extension Data {
    func append(to url: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: url)
        }
    }
}
```

### 示例 4: 批量处理

处理多个视频文件。

```swift
import VideoAnalysisSDK

class BatchProcessor {
    private var currentService: VideoAnalysisServiceProtocol?
    private var videoQueue: [URL] = []
    private var isProcessing = false
    
    func processVideos(_ videos: [URL], modelURL: URL) {
        videoQueue = videos
        processNext(modelURL: modelURL)
    }
    
    private func processNext(modelURL: URL) {
        guard !videoQueue.isEmpty else {
            print("所有视频处理完成!")
            return
        }
        
        guard !isProcessing else { return }
        
        let videoURL = videoQueue.removeFirst()
        isProcessing = true
        
        print("\n处理视频: \(videoURL.lastPathComponent)")
        print("剩余: \(videoQueue.count)个")
        
        do {
            currentService = try VideoAnalysisSDK.createVideoAnalysisService(
                modelURL: modelURL,
                config: .default,
                clipConfig: VideoClipConfig(
                    outputDirectory: URL(fileURLWithPath: "~/Desktop/BatchOutput"),
                    sessionName: videoURL.deletingPathExtension().lastPathComponent
                )
            )
            
            let callbacks = VideoAnalysisCallbacks(
                onProgress: { progress in
                    print("  进度: \(Int(progress * 100))%")
                },
                onEvent: { event in
                    if case .eventDetected(let timestamp, _) = event {
                        print("  检测到进球: \(timestamp)秒")
                    }
                },
                onCompletion: { [weak self] result in
                    print("  完成! 处理了 \(result.totalFrames) 帧")
                    self?.isProcessing = false
                    self?.processNext(modelURL: modelURL)
                },
                onError: { [weak self] error in
                    print("  错误: \(error.localizedDescription)")
                    self?.isProcessing = false
                    self?.processNext(modelURL: modelURL)
                }
            )
            
            currentService?.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("  初始化失败: \(error)")
            isProcessing = false
            processNext(modelURL: modelURL)
        }
    }
    
    func stop() {
        currentService?.stop()
        videoQueue.removeAll()
        isProcessing = false
    }
}

// 使用示例
let processor = BatchProcessor()
let videos = [
    URL(fileURLWithPath: "~/Videos/game1.mp4"),
    URL(fileURLWithPath: "~/Videos/game2.mp4"),
    URL(fileURLWithPath: "~/Videos/game3.mp4")
]
let modelURL = URL(fileURLWithPath: "~/Models/yolo.mlmodelc")

processor.processVideos(videos, modelURL: modelURL)
```

---

## 最佳实践

### 1. 配置选择

#### 首次使用
```swift
// 使用默认配置，快速开始
let config = VideoAnalysisConfig.default
```

#### 开发调试
```swift
var config = VideoAnalysisConfig.default
config.debugMode = true          // 开启详细日志
config.maxLogCount = 2000        // 增加日志容量
```

#### 生产环境
```swift
var config = VideoAnalysisConfig.default
config.debugMode = false         // 关闭调试日志
config.maxLogCount = 500         // 减少内存占用
```

#### 长视频处理
```swift
var config = VideoAnalysisConfig.performance
config.frameSkip = 5             // 增加跳帧
config.calibrationFrames = 20    // 减少校准帧
```

#### 高精度要求
```swift
var config = VideoAnalysisConfig.highPrecision
config.frameSkip = 2             // 减少跳帧
config.calibrationFrames = 40    // 增加校准帧
```

### 2. 内存管理

#### 使用弱引用避免循环引用
```swift
let callbacks = VideoAnalysisCallbacks(
    onLog: { [weak self] log in
        self?.logs.append(log)
    },
    onProgress: { [weak self] progress in
        self?.progress = progress
    }
)
```

#### 及时释放资源
```swift
class Analyzer {
    var service: VideoAnalysisServiceProtocol?
    
    func cleanup() {
        service?.stop()
        service = nil
    }
    
    deinit {
        cleanup()
    }
}
```

#### 限制日志数量
```swift
var config = VideoAnalysisConfig.default
config.maxLogCount = 1000  // 限制内存中的日志数量
```

### 3. 错误处理

#### 完整的错误处理
```swift
do {
    let service = try VideoAnalysisSDK.createVideoAnalysisService(
        modelURL: modelURL,
        config: config,
        clipConfig: clipConfig
    )
    
    let callbacks = VideoAnalysisCallbacks(
        onError: { error in
            if let analysisError = error as? VideoAnalysisError {
                switch analysisError {
                case .videoLoadFailed(let reason):
                    // 视频文件问题
                    self.handleVideoError(reason)
                    
                case .modelNotFound(let path):
                    // 模型文件不存在
                    self.handleModelError(path)
                    
                case .modelLoadFailed(let reason):
                    // 模型加载失败
                    self.handleModelLoadError(reason)
                    
                case .readerCreationFailed(let reason):
                    // 读取器创建失败
                    self.handleReaderError(reason)
                    
                case .invalidTimeRange:
                    // 时间范围无效
                    self.handleTimeRangeError()
                    
                case .clipExportFailed(let reason):
                    // 剪辑导出失败
                    self.handleClipError(reason)
                    
                case .unknown(let reason):
                    // 未知错误
                    self.handleUnknownError(reason)
                }
            }
        }
    )
    
    service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
    
} catch {
    // 初始化失败
    print("SDK 初始化失败: \(error)")
}
```

#### 错误恢复策略
```swift
class RobustAnalyzer {
    private var retryCount = 0
    private let maxRetries = 3
    
    func analyzeWithRetry(videoURL: URL, modelURL: URL) {
        do {
            let service = try VideoAnalysisSDK.createVideoAnalysisService(
                modelURL: modelURL,
                config: .default
            )
            
            let callbacks = VideoAnalysisCallbacks(
                onError: { [weak self] error in
                    guard let self = self else { return }
                    
                    if self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        print("重试 \(self.retryCount)/\(self.maxRetries)...")
                        
                        // 等待后重试
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.analyzeWithRetry(videoURL: videoURL, modelURL: modelURL)
                        }
                    } else {
                        print("达到最大重试次数，放弃")
                        self.handleFinalError(error)
                    }
                },
                onCompletion: { [weak self] _ in
                    self?.retryCount = 0  // 重置重试计数
                }
            )
            
            service.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("初始化失败: \(error)")
        }
    }
    
    private func handleFinalError(_ error: Error) {
        // 最终错误处理
    }
}
```

### 4. 性能优化

#### 根据设备性能调整配置
```swift
func getOptimalConfig() -> VideoAnalysisConfig {
    let processorCount = ProcessInfo.processInfo.processorCount
    let physicalMemory = ProcessInfo.processInfo.physicalMemory
    
    var config = VideoAnalysisConfig.default
    
    // 根据 CPU 核心数调整
    if processorCount >= 8 {
        config.frameSkip = 2  // 高性能设备
    } else if processorCount >= 4 {
        config.frameSkip = 3  // 中等性能设备
    } else {
        config.frameSkip = 5  // 低性能设备
    }
    
    // 根据内存调整
    let memoryGB = Double(physicalMemory) / 1024 / 1024 / 1024
    if memoryGB < 8 {
        config.maxLogCount = 500
        config.debugMode = false
    }
    
    return config
}
```

#### 剪辑性能优化
```swift
func getOptimalClipConfig() -> VideoClipConfig {
    let processorCount = ProcessInfo.processInfo.processorCount
    
    return VideoClipConfig(
        maxConcurrentExports: min(processorCount / 2, 4),  // 不超过4个并发
        exportTimeout: 120
    )
}
```

### 5. 线程安全

#### UI 更新
```swift
// SDK 的回调已经在主线程，可以直接更新 UI
let callbacks = VideoAnalysisCallbacks(
    onProgress: { progress in
        self.progressBar.progress = Float(progress)  // 直接更新
    }
)
```

#### 后台任务
```swift
let callbacks = VideoAnalysisCallbacks(
    onClipCreated: { clip in
        // 如果需要后台处理
        DispatchQueue.global(qos: .utility).async {
            self.processClipInBackground(clip)
        }
    }
)
```

### 6. 日志管理

#### 保存日志到文件
```swift
class LogManager {
    private let logFileURL: URL
    
    init() {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        logFileURL = documentsPath.appendingPathComponent("analysis.log")
    }
    
    func setupLogging() -> (String) -> Void {
        return { [weak self] log in
            guard let self = self else { return }
            
            let timestamp = DateFormatter.localizedString(
                from: Date(),
                dateStyle: .short,
                timeStyle: .medium
            )
            let logLine = "[\(timestamp)] \(log)\n"
            
            if let data = logLine.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: self.logFileURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: self.logFileURL)
                }
            }
        }
    }
}

// 使用
let logManager = LogManager()
let callbacks = VideoAnalysisCallbacks(
    onLog: logManager.setupLogging()
)
```

#### 日志过滤
```swift
let callbacks = VideoAnalysisCallbacks(
    onLog: { log in
        // 只记录重要日志
        if log.contains("错误") || log.contains("警告") || log.contains("进球") {
            print(log)
            saveToFile(log)
        }
    }
)
```

### 7. 测试建议

#### 单元测试
```swift
import XCTest
@testable import VideoAnalysisSDK

class VideoAnalysisTests: XCTestCase {
    func testDefaultConfig() {
        let config = VideoAnalysisConfig.default
        XCTAssertEqual(config.frameSkip, 3)
        XCTAssertEqual(config.calibrationFrames, 30)
    }
    
    func testServiceCreation() throws {
        let modelURL = Bundle(for: type(of: self))
            .url(forResource: "test_model", withExtension: "mlmodelc")!
        
        let service = try VideoAnalysisSDK.createVideoAnalysisService(
            modelURL: modelURL,
            config: .default
        )
        
        XCTAssertNotNil(service)
        XCTAssertFalse(service.isRunning)
    }
}
```

#### 集成测试
```swift
func testVideoAnalysis() {
    let expectation = XCTestExpectation(description: "分析完成")
    
    let service = try! VideoAnalysisSDK.createVideoAnalysisService(
        modelURL: testModelURL,
        config: .default
    )
    
    let callbacks = VideoAnalysisCallbacks(
        onCompletion: { result in
            XCTAssertGreaterThan(result.totalFrames, 0)
            expectation.fulfill()
        },
        onError: { error in
            XCTFail("分析失败: \(error)")
            expectation.fulfill()
        }
    )
    
    service.startAnalysis(videoURL: testVideoURL, callbacks: callbacks)
    
    wait(for: [expectation], timeout: 60.0)
}
```

### 8. 调试技巧

#### 开启详细日志
```swift
var config = VideoAnalysisConfig.default
config.debugMode = true
config.maxLogCount = 5000
```

#### 使用断点调试
```swift
let callbacks = VideoAnalysisCallbacks(
    onEvent: { event in
        // 在这里设置断点
        print("事件: \(event)")
    }
)
```

#### 性能分析
```swift
import os.signpost

let log = OSLog(subsystem: "com.app.analysis", category: "Performance")

let callbacks = VideoAnalysisCallbacks(
    onProgress: { progress in
        os_signpost(.event, log: log, name: "Progress", "%.2f%%", progress * 100)
    }
)
```

---
