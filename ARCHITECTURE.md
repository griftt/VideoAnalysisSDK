# VideoAnalysisSDK 架构文档

## 概述

VideoAnalysisSDK 是一个模块化的视频分析框架，集成了推理、视频分析和视频剪辑功能。设计目标是易于使用、易于扩展、易于跨平台移植。

## 核心设计原则

1. **模块化** - 各模块独立解耦，可单独使用
2. **协议驱动** - 使用协议定义接口，便于扩展和测试
3. **配置化** - 所有参数可配置，提供多种预设
4. **类型安全** - 充分利用 Swift 类型系统
5. **内存安全** - 自动内存管理，防止内存泄漏

## 模块架构

### 1. 推理模块 (Inference)

**职责**: 执行对象检测推理

**核心类**:
- `InferenceServiceProtocol` - 推理服务协议
- `CoreMLInferenceService` - CoreML 实现
- `InferenceConfig` - 推理配置

**数据流**:
```
CVPixelBuffer → InferenceService → [DetectedObject]
```

**扩展点**:
- 实现 `InferenceServiceProtocol` 支持其他推理引擎（TensorFlow Lite, ONNX等）

### 2. 视频分析模块 (VideoAnalysis)

**职责**: 逐帧分析视频，检测事件

**核心类**:
- `VideoAnalysisServiceProtocol` - 分析服务协议
- `VideoAnalysisService` - 分析服务实现
- `VideoAnalysisConfig` - 分析配置
- `VideoAnalysisCallbacks` - 回调接口

**数据流**:
```
Video File → Frame Reader → InferenceService → AnalysisLogicService → Events
```

**状态管理**:
- `isRunning` - 运行状态
- `isPaused` - 暂停状态
- 线程安全的状态访问

**扩展点**:
- 自定义 `AnalysisLogicService` 实现不同的检测逻辑

### 3. 检测逻辑模块 (Logic)

**职责**: 处理检测逻辑，判定事件

**核心类**:
- `AnalysisLogicService` - 检测逻辑服务

**处理流程**:
1. **校准阶段** - 收集目标位置样本，计算平均位置
2. **检测阶段** - 根据对象位置和交互判定事件

**扩展点**:
- 继承 `AnalysisLogicService` 实现自定义检测逻辑
- 支持不同的运动场景（篮球、足球、网球等）

### 4. 视频剪辑模块 (VideoClip)

**职责**: 剪辑视频片段

**核心类**:
- `VideoClipServiceProtocol` - 剪辑服务协议
- `VideoClipService` - 剪辑服务实现
- `VideoClipConfig` - 剪辑配置

**数据流**:
```
Video File + Timestamp → AVAssetExportSession → Clip File
```

**并发控制**:
- 使用信号量限制并发数
- 防止内存爆炸

**扩展点**:
- 实现 `VideoClipServiceProtocol` 支持其他剪辑方式

## 数据模型

### DetectedObject

检测到的对象，包含：
- `label` - 对象标签
- `confidence` - 置信度
- `boundingBox` - 边界框
- `timestamp` - 时间戳（可选）

### AnalysisEvent

分析事件，包含：
- `calibrating` - 校准中
- `calibrated` - 校准完成
- `eventDetected` - 事件检测
- `custom` - 自定义事件

### AnalysisResult

分析结果，包含：
- `events` - 事件列表
- `totalFrames` - 总帧数
- `duration` - 处理时长
- `averageFPS` - 平均FPS

### ClipResult

剪辑结果，包含：
- `url` - 文件URL
- `index` - 索引
- `timestamp` - 时间戳
- `duration` - 时长
- `fileSize` - 文件大小

## 配置系统

### 三层配置

1. **InferenceConfig** - 推理配置
   - 置信度阈值
   - NMS 阈值
   - 标签过滤

2. **VideoAnalysisConfig** - 分析配置
   - 推理配置
   - 性能参数
   - 检测参数

3. **VideoClipConfig** - 剪辑配置
   - 时间参数
   - 并发控制
   - 输出设置

### 预设配置

- `default` - 默认配置
- `highPrecision` - 高精度
- `highRecall` - 高召回
- `performance` - 性能优化

## 回调系统

### VideoAnalysisCallbacks

提供6种回调：
1. `onLog` - 日志输出
2. `onProgress` - 进度更新
3. `onEvent` - 事件检测
4. `onClipCreated` - 剪辑完成
5. `onCompletion` - 分析完成
6. `onError` - 错误处理

所有回调在主线程执行，确保UI安全。

## 内存管理

### 优化策略

1. **autoreleasepool** - 每帧处理使用独立的 autoreleasepool
2. **分辨率限制** - 限制视频分辨率为 1280x720
3. **跳帧处理** - 校准后按配置跳帧
4. **并发控制** - 限制同时进行的剪辑任务数

### 资源释放

- 及时释放 AVAssetReader
- 取消未完成的导出任务
- 清空校准缓冲区

## 线程模型

### 线程使用

1. **主线程** - UI 回调
2. **推理线程** - 推理计算（QoS: userInitiated）
3. **分析线程** - 视频分析（QoS: userInitiated）
4. **剪辑线程** - 视频剪辑（QoS: userInitiated）

### 线程安全

- 使用 NSLock 保护共享状态
- 所有回调切换到主线程

## 错误处理

### 错误类型

- `modelNotFound` - 模型未找到
- `videoLoadFailed` - 视频加载失败
- `readerCreationFailed` - 读取器创建失败
- `exportFailed` - 导出失败
- `invalidTimeRange` - 无效时间范围
- `cancelled` - 操作取消
- `timeout` - 操作超时

### 错误传播

通过 `onError` 回调传递错误，不会崩溃应用。

## 扩展指南

### 添加新的推理引擎

```swift
class TensorFlowLiteInferenceService: InferenceServiceProtocol {
    func performInference(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) -> [DetectedObject] {
        // 实现 TensorFlow Lite 推理
    }
}
```

### 添加新的检测逻辑

```swift
class SoccerLogicService: AnalysisLogicService {
    override func processEventDetection(
        objects: [DetectedObject],
        timestamp: TimeInterval
    ) -> AnalysisEvent? {
        // 实现足球检测逻辑
    }
}
```

### 添加新的剪辑方式

```swift
class CustomClipService: VideoClipServiceProtocol {
    func exportClip(
        from sourceURL: URL,
        at timestamp: TimeInterval,
        index: Int,
        completion: @escaping (Result<ClipResult, Error>) -> Void
    ) {
        // 实现自定义剪辑
    }
}
```

## 跨平台移植

### Android 移植

1. **推理层**: CoreML → TensorFlow Lite
2. **视频处理**: AVFoundation → MediaCodec
3. **剪辑**: AVAssetExportSession → MediaMuxer

### Flutter 移植

1. 创建 Platform Channel
2. 封装原生 SDK
3. 提供 Dart API

### Web 移植

1. **推理层**: CoreML → TensorFlow.js
2. **视频处理**: AVFoundation → Web APIs
3. **剪辑**: AVAssetExportSession → FFmpeg.wasm

## 性能指标

### 目标性能

- 推理速度: > 30 FPS (iPhone 12+)
- 内存占用: < 500 MB
- 剪辑速度: 实时或更快

### 优化建议

1. 使用跳帧减少计算量
2. 限制视频分辨率
3. 控制并发剪辑数量
4. 启用内存优化

## 测试策略

### 单元测试

- 模型测试（BoundingBox, DetectedObject）
- 配置测试（Config 类）
- 逻辑测试（AnalysisLogicService）

### 集成测试

- 端到端视频分析
- 剪辑功能测试
- 错误处理测试

### 性能测试

- 内存泄漏检测
- 性能基准测试
- 并发压力测试

## 未来规划

1. 支持更多推理引擎
2. 支持更多平台（Android, Web）
3. 添加更多预设检测逻辑
4. 性能分析工具
5. 视频预览功能
6. 批量处理优化
