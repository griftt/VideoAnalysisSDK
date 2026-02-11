# VideoAnalysisSDK

🏀 一个专为篮球视频分析设计的完整 SDK，集成了推理、进球检测和精彩片段剪辑功能。

## ✨ 特性

### 核心功能

- 🎯 **智能推理** - 基于 CoreML 的篮球和篮筐检测
- � **进球检测** - 自动识别进球时刻
- ✂️ **自动剪辑** - 自动生成进球集锦视频
- 🎛 **灵活配置** - 多种预设配置，适应不同场景
- 🔄 **状态管理** - 支持暂停、恢复、停止操作
- 📊 **实时反馈** - 进度追踪和事件回调

### 技术特点

- ✅ **模块化设计** - 推理、分析、剪辑独立解耦，可单独使用
- ✅ **跨平台支持** - iOS、macOS、tvOS，易于移植到 Android/Web
- ✅ **内存优化** - 自动内存管理，支持长视频处理
- ✅ **并发控制** - 智能并发剪辑，防止内存爆炸
- ✅ **类型安全** - 完整的 Swift 类型系统
- ✅ **易于扩展** - 支持自定义检测逻辑（足球、网球等）

## 📦 安装

### Swift Package Manager

在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/VideoAnalysisSDK.git", from: "1.0.0")
]
```

## 🚀 快速开始

### 完整示例：从视频到进球集锦

这是一个完整的示例，展示如何使用 SDK 分析篮球视频并自动生成进球集锦。

```swift
import VideoAnalysisSDK
import UIKit

class BasketballAnalysisViewController: UIViewController {
    
    // 1. 准备视频URL
    let videoURL = URL(fileURLWithPath: "/path/to/basketball_game.mp4")
    
    // 2. 存储分析服务
    var analysisService: VideoAnalysisServiceProtocol?
    
    // 3. 存储生成的集锦URL
    var highlightClips: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startBasketballAnalysis()
    }
    
    func startBasketballAnalysis() {
        do {
            // ========== 步骤 1: 配置 SDK ==========
            
            // 推理配置：设置篮球和篮筐检测参数
            let inferenceConfig = InferenceConfig(
                confidenceThreshold: 0.15,      // 置信度阈值
                nmsThreshold: 0.45,             // NMS 阈值
                maxDetections: 100,             // 最大检测数量
                enableMemoryOptimization: true, // 启用内存优化
                labelFilter: ["basketball", "rim"]  // 只检测篮球和篮筐
            )
            
            // 视频分析配置：设置进球检测参数
            let analysisConfig = VideoAnalysisConfig(
                inferenceConfig: inferenceConfig,
                frameSkip: 3,                   // 每3帧处理一次（提高性能）
                calibrationFrames: 30,          // 用30帧校准篮筐位置
                startTime: nil,                 // 从头开始（可设置具体时间）
                endTime: nil,                   // 分析到结束（可设置具体时间）
                eventWindow: 2.5,               // 进球判定时间窗口（秒）
                eventCooldown: 3.0,             // 两次进球最小间隔（秒）
                targetZoneHeight: 0.06,         // 目标区域高度
                interactionDistanceThreshold: 0.20,  // 交互距离阈值
                debugMode: true                 // 启用调试日志
            )
            
            // ========== 步骤 2: 创建分析服务 ==========
            
            analysisService = try VideoAnalysisSDK.createVideoAnalysisService(
                modelName: "best",              // 你的 CoreML 模型名称
                bundle: .main,                  // 模型所在的 Bundle
                config: analysisConfig
            )
            
            // ========== 步骤 3: 设置回调 ==========
            
            let callbacks = VideoAnalysisCallbacks(
                // 日志回调：显示分析过程
                onLog: { [weak self] message in
                    print("📝 \(message)")
                    // 可以更新 UI 显示日志
                    DispatchQueue.main.async {
                        self?.updateLogLabel(message)
                    }
                },
                
                // 进度回调：更新进度条
                onProgress: { [weak self] progress in
                    print("📊 进度: \(Int(progress * 100))%")
                    DispatchQueue.main.async {
                        self?.updateProgressBar(progress)
                    }
                },
                
                // 事件回调：处理检测事件
                onEvent: { [weak self] event in
                    switch event {
                    case .calibrating(let current, let target):
                        print("🟢 正在校准篮筐位置... \(current)/\(target)")
                        
                    case .calibrated(let box):
                        print("✅ 篮筐位置已锁定: \(box)")
                        
                    case .eventDetected(let timestamp, _):
                        print("🏀 检测到进球！时间: \(String(format: "%.2f", timestamp))秒")
                        DispatchQueue.main.async {
                            self?.showGoalDetectedAlert(at: timestamp)
                        }
                        
                    case .custom(let name, _):
                        print("📌 自定义事件: \(name)")
                    }
                },
                
                // 剪辑完成回调：保存集锦URL
                onClipCreated: { [weak self] clipResult in
                    print("✂️ 进球集锦 #\(clipResult.index) 已生成")
                    print("   文件: \(clipResult.url.lastPathComponent)")
                    print("   大小: \(clipResult.fileSize / 1024 / 1024) MB")
                    print("   时长: \(String(format: "%.2f", clipResult.duration))秒")
                    
                    // 保存集锦URL
                    self?.highlightClips.append(clipResult.url)
                    
                    // 更新UI显示集锦列表
                    DispatchQueue.main.async {
                        self?.updateHighlightsList()
                    }
                },
                
                // 完成回调：显示分析结果
                onCompletion: { [weak self] result in
                    print("✅ 分析完成！")
                    print("   处理帧数: \(result.totalFrames)")
                    print("   耗时: \(String(format: "%.2f", result.duration))秒")
                    print("   平均FPS: \(String(format: "%.2f", result.averageFPS))")
                    print("   生成集锦: \(self?.highlightClips.count ?? 0) 个")
                    
                    DispatchQueue.main.async {
                        self?.showCompletionAlert(result: result)
                    }
                },
                
                // 错误回调：处理错误
                onError: { [weak self] error in
                    print("❌ 错误: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.showErrorAlert(error: error)
                    }
                }
            )
            
            // ========== 步骤 4: 开始分析 ==========
            
            print("🎬 开始分析篮球视频...")
            analysisService?.startAnalysis(videoURL: videoURL, callbacks: callbacks)
            
        } catch {
            print("❌ 初始化失败: \(error.localizedDescription)")
            showErrorAlert(error: error)
        }
    }
    
    // ========== 控制方法 ==========
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        analysisService?.pause()
        print("⏸️ 分析已暂停")
    }
    
    @IBAction func resumeButtonTapped(_ sender: UIButton) {
        analysisService?.resume()
        print("▶️ 分析已恢复")
    }
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        analysisService?.stop()
        print("🛑 分析已停止")
    }
    
    // ========== UI 更新方法（示例） ==========
    
    func updateLogLabel(_ message: String) {
        // 更新日志标签
    }
    
    func updateProgressBar(_ progress: Double) {
        // 更新进度条
    }
    
    func showGoalDetectedAlert(at timestamp: TimeInterval) {
        // 显示进球提示
    }
    
    func updateHighlightsList() {
        // 更新集锦列表
    }
    
    func showCompletionAlert(result: AnalysisResult) {
        let alert = UIAlertController(
            title: "分析完成",
            message: "共检测到 \(highlightClips.count) 个进球，已生成集锦视频",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "查看集锦", style: .default) { _ in
            // 播放集锦视频
        })
        alert.addAction(UIAlertAction(title: "确定", style: .cancel))
        present(alert, animated: true)
    }
    
    func showErrorAlert(error: Error) {
        let alert = UIAlertController(
            title: "错误",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### 运行结果示例

```
🎬 开始分析篮球视频...
📝 🎬 开始分析: basketball_game.mp4
📝 🟢 正在校准篮筐位置... 10/30
📝 🟢 正在校准篮筐位置... 20/30
📝 🟢 正在校准篮筐位置... 30/30
📝 ✅ 篮筐位置已锁定: (0.45, 0.32, 0.15, 0.08)
📊 进度: 15%
📝 🏀 检测到进球！时间: 12.50秒
📝 🎬 开始剪辑进球片段...
📊 进度: 35%
✂️ 进球集锦 #1 已生成
   文件: clip_1_12s.mp4
   大小: 2.5 MB
   时长: 6.00秒
📝 🏀 检测到进球！时间: 28.30秒
📊 进度: 65%
✂️ 进球集锦 #2 已生成
   文件: clip_2_28s.mp4
   大小: 2.3 MB
   时长: 6.00秒
📊 进度: 100%
✅ 分析完成！
   处理帧数: 1800
   耗时: 45.30秒
   平均FPS: 39.73
   生成集锦: 2 个
```

## 📚 工作原理

### 篮球进球检测流程

```
1. 视频输入
   └─> basketball_game.mp4

2. 逐帧读取
   └─> 每3帧处理一次（可配置）

3. 推理检测
   └─> CoreML 模型检测篮球和篮筐
   └─> 输出：[DetectedObject]

4. 篮筐校准（前30帧）
   └─> 收集篮筐位置样本
   └─> 计算平均位置
   └─> 锁定篮筐位置

5. 进球判定
   └─> 检测篮球与篮筐的交互
   └─> 判断篮球是否进入目标区域
   └─> 时间窗口内判定进球

6. 自动剪辑
   └─> 进球时刻前4秒 + 后2秒
   └─> 生成集锦视频文件
   └─> 保存到指定目录

7. 输出结果
   └─> clip_1_12s.mp4
   └─> clip_2_28s.mp4
   └─> ...
```

### 模块架构

```
VideoAnalysisSDK
├── 推理模块 (Inference)
│   └── 检测篮球和篮筐
│
├── 分析模块 (VideoAnalysis)
│   ├── 逐帧读取视频
│   ├── 调用推理模块
│   └── 协调整体流程
│
├── 逻辑模块 (Logic)
│   ├── 篮筐位置校准
│   ├── 进球判定逻辑
│   └── 事件检测
│
└── 剪辑模块 (VideoClip)
    ├── 视频片段导出
    └── 并发控制
```

## ⚙️ 配置选项

### 推理配置 (InferenceConfig)

```swift
let inferenceConfig = InferenceConfig(
    confidenceThreshold: 0.15,      // 置信度阈值
    nmsThreshold: 0.45,             // NMS IoU 阈值
    maxDetections: 100,             // 最大检测数量
    enableMemoryOptimization: true, // 启用内存优化
    labelFilter: ["basketball", "rim"]  // 标签过滤
)
```

### 视频分析配置 (VideoAnalysisConfig)

```swift
let analysisConfig = VideoAnalysisConfig(
    inferenceConfig: inferenceConfig,
    frameSkip: 3,                   // 跳帧数
    calibrationFrames: 30,          // 校准帧数
    startTime: 0.0,                 // 开始时间
    endTime: nil,                   // 结束时间（nil=全部）
    eventWindow: 2.5,               // 事件检测窗口
    eventCooldown: 3.0,             // 事件冷却时间
    debugMode: false                // 调试模式
)
```

### 剪辑配置 (VideoClipConfig)

```swift
let clipConfig = VideoClipConfig(
    leadTime: 4.0,                  // 前置时间
    trailTime: 2.0,                 // 后置时间
    maxConcurrentExports: 2,        // 最大并发数
    exportTimeout: 120,             // 超时时间
    outputDirectory: nil,           // 输出目录（nil=默认）
    sessionName: "MySession"        // 会话名称
)
```

## 🎯 使用场景

### 场景 1：完整的篮球比赛分析

```swift
// 分析整场比赛，自动生成所有进球集锦
let config = VideoAnalysisConfig.default
let service = try VideoAnalysisSDK.createVideoAnalysisService(
    modelName: "best",
    config: config
)
service.startAnalysis(videoURL: gameVideoURL, callbacks: callbacks)
```

### 场景 2：只分析比赛的某个时间段

```swift
// 只分析第二节（10分钟到20分钟）
let config = VideoAnalysisConfig(
    inferenceConfig: .default,
    startTime: 600.0,   // 从10分钟开始
    endTime: 1200.0     // 到20分钟结束
)
let service = try VideoAnalysisSDK.createVideoAnalysisService(
    modelName: "best",
    config: config
)
```

### 场景 3：高精度检测（减少误判）

```swift
// 使用更严格的阈值，减少误判
let config = VideoAnalysisConfig(
    inferenceConfig: InferenceConfig(
        confidenceThreshold: 0.3,  // 更高的置信度要求
        labelFilter: ["basketball", "rim"]
    ),
    eventWindow: 2.0,              // 更短的判定窗口
    eventCooldown: 4.0,            // 更长的冷却时间
    targetZoneHeight: 0.04         // 更小的目标区域
)
```

### 场景 4：快速处理（性能优先）

```swift
// 使用性能优化配置，适合长视频或低端设备
let config = VideoAnalysisConfig.performance
let service = try VideoAnalysisSDK.createVideoAnalysisService(
    modelName: "best",
    config: config
)
```

### 场景 5：只使用推理功能（不分析不剪辑）

```swift
// 只检测篮球和篮筐，不做进球判定
let inferenceService = try VideoAnalysisSDK.createInferenceService(
    modelName: "best",
    config: InferenceConfig(labelFilter: ["basketball", "rim"])
)

// 对单帧图像进行推理
let objects = inferenceService.performInference(
    pixelBuffer: pixelBuffer,
    orientation: .up
)

for object in objects {
    print("\(object.label): \(object.confidence)")
}
```

### 场景 6：只使用剪辑功能（手动指定时间点）

```swift
// 手动指定进球时间点，只做剪辑
let clipService = VideoAnalysisSDK.createVideoClipService(
    config: VideoClipConfig(leadTime: 5.0, trailTime: 3.0)
)

let goalTimestamps = [12.5, 28.3, 45.7, 62.1]  // 手动标记的进球时间

for (index, timestamp) in goalTimestamps.enumerated() {
    clipService.exportClip(
        from: videoURL,
        at: timestamp,
        index: index + 1
    ) { result in
        if case .success(let clip) = result {
            print("✅ 集锦 #\(clip.index) 已生成")
        }
    }
}
```

## ⚙️ 配置参数详解

### 推理配置 (InferenceConfig)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `confidenceThreshold` | Float | 0.15 | 置信度阈值，低于此值的检测结果会被过滤 |
| `nmsThreshold` | Float | 0.45 | NMS IoU 阈值，用于过滤重叠的检测框 |
| `maxDetections` | Int | 100 | 每帧最大检测数量 |
| `enableMemoryOptimization` | Bool | true | 是否启用内存优化（使用 autoreleasepool） |
| `labelFilter` | Set<String>? | nil | 标签过滤器，只返回指定标签的检测结果 |

### 视频分析配置 (VideoAnalysisConfig)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `frameSkip` | Int | 3 | 跳帧数，每N帧处理一次（提高性能） |
| `calibrationFrames` | Int | 30 | 校准所需帧数，用于稳定篮筐位置 |
| `startTime` | TimeInterval? | nil | 开始时间（秒），nil 表示从头开始 |
| `endTime` | TimeInterval? | nil | 结束时间（秒），nil 表示到视频结束 |
| `eventWindow` | TimeInterval | 2.5 | 进球判定时间窗口（秒） |
| `eventCooldown` | TimeInterval | 3.0 | 两次进球最小间隔（秒） |
| `minInteractionInterval` | TimeInterval | 0.05 | 最小交互时间间隔（秒） |
| `targetZoneHeight` | CGFloat | 0.06 | 目标区域高度（归一化坐标） |
| `targetZoneHorizontalExpansion` | CGFloat | 0.01 | 目标区域水平扩展（归一化坐标） |
| `interactionDistanceThreshold` | CGFloat | 0.20 | 交互判定距离阈值（归一化坐标） |
| `expansionFactor` | CGFloat | 0.10 | 篮筐扩展区域系数 |
| `closeProximityThreshold` | CGFloat | 0.15 | 近距离判定阈值（归一化坐标） |
| `debugMode` | Bool | false | 是否启用调试模式（输出详细日志） |

### 剪辑配置 (VideoClipConfig)

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `leadTime` | TimeInterval | 4.0 | 剪辑前置时间（秒），进球前多少秒开始 |
| `trailTime` | TimeInterval | 2.0 | 剪辑后置时间（秒），进球后多少秒结束 |
| `maxConcurrentExports` | Int | 2 | 最大并发剪辑任务数 |
| `exportTimeout` | TimeInterval | 120 | 单个剪辑任务超时时间（秒） |
| `outputDirectory` | URL? | nil | 输出目录，nil 表示使用默认目录 |
| `sessionName` | String? | nil | 会话名称，用于创建子文件夹 |

### 预设配置

```swift
// 默认配置（推荐）
VideoAnalysisConfig.default

// 高精度配置（减少误判）
VideoAnalysisConfig.highPrecision

// 性能优化配置（适合长视频）
VideoAnalysisConfig.performance
```

## 📊 性能优化

### 内存优化

- ✅ 自动使用 `autoreleasepool` 管理内存
- ✅ 限制视频分辨率（1280x720）
- ✅ 跳帧处理减少计算量
- ✅ 并发控制防止内存爆炸

### 速度优化

- ✅ 校准后跳帧处理
- ✅ 异步推理和剪辑
- ✅ 智能并发控制
- ✅ NMS 优化检测结果

## 🔧 常见问题

### Q1: 如何提高检测准确率？

**A**: 调整以下参数：
- 提高 `confidenceThreshold`（如 0.3）
- 减小 `targetZoneHeight`（如 0.04）
- 增加 `eventCooldown`（如 4.0）
- 减小 `eventWindow`（如 2.0）

### Q2: 如何提高处理速度？

**A**: 使用性能优化配置：
- 增加 `frameSkip`（如 5）
- 减少 `calibrationFrames`（如 20）
- 使用 `VideoAnalysisConfig.performance`

### Q3: 视频太长，内存不足怎么办？

**A**: SDK 已内置内存优化，但你还可以：
- 分段处理视频（使用 `startTime` 和 `endTime`）
- 增加 `frameSkip`
- 减少 `maxConcurrentExports`

### Q4: 如何获取集锦文件的保存路径？

**A**: 在 `onClipCreated` 回调中获取：
```swift
onClipCreated: { clipResult in
    print("文件路径: \(clipResult.url.path)")
    // 默认路径: Documents/VideoClips/Session_xxx/clip_1_12s.mp4
}
```

### Q5: 可以用于其他运动吗？

**A**: 可以！只需：
1. 训练对应的 CoreML 模型
2. 修改 `labelFilter`（如 `["ball", "goal"]` 用于足球）
3. 调整检测参数（如 `targetZoneHeight`）

### Q6: 如何暂停和恢复分析？

**A**: 使用控制方法：
```swift
analysisService.pause()   // 暂停
analysisService.resume()  // 恢复
analysisService.stop()    // 停止
```

## 🔌 推理引擎扩展

SDK 使用**策略模式**设计，支持灵活切换推理引擎。只需实现 `InferenceServiceProtocol` 协议即可。

### 内置推理引擎

#### 1. CoreML 推理（本地）

```swift
// 使用本地 CoreML 模型
let service = try VideoAnalysisSDK.createInferenceService(
    modelName: "best",
    config: .default
)
```

**特点**：
- ✅ 快速（本地推理）
- ✅ 离线可用
- ✅ 隐私保护
- ❌ 需要设备支持

#### 2. 云端 API 推理（远程）

```swift
// 配置云端 API
let apiConfig = CloudAPIInfere

## 📋 系统要求

- iOS 14.0+
- macOS 11.0+
- tvOS 14.0+
- Swift 5.9+
- Xcode 15.0+

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

Made with ❤️ by VideoAnalysisSDK Team
