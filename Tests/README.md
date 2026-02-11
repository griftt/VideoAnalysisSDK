# VideoAnalysisSDK 测试指南

## 📋 测试概述

本目录包含 VideoAnalysisSDK 的完整测试套件，包括单元测试和集成测试。

## 🧪 测试类型

### 1. 单元测试

测试 SDK 的各个组件和数据模型：

- **BoundingBox 测试**: 测试边界框的计算（中心点、IoU、距离）
- **配置测试**: 测试各种配置的默认值和预设
- **模型测试**: 测试数据模型的编码/解码

### 2. 集成测试

测试完整的进球检测和剪辑流程：

- **进球检测和剪辑测试** (`testGoalDetectionAndClipping`)
- **仅检测测试** (`testGoalDetectionOnly`)
- **自定义配置测试** (`testCustomClipConfiguration`)

## 🚀 运行测试

### 运行所有测试

```bash
swift test
```

### 运行特定测试

```bash
# 运行单元测试
swift test --filter VideoAnalysisSDKTests.testBoundingBoxCenter

# 运行进球检测测试
swift test --filter VideoAnalysisSDKTests.testGoalDetectionAndClipping
```

### 在 Xcode 中运行

1. 打开 Package.swift
2. 选择测试目标
3. 按 `Cmd + U` 运行所有测试
4. 或点击测试方法旁的菱形图标运行单个测试

## 📝 进球检测测试说明

### 准备测试数据

进球检测测试需要以下文件：

#### 1. 测试视频

将测试视频放在以下位置之一：

```
/tmp/test_basketball.mp4
```

或者在项目的 `Tests/Resources/` 目录中（需要创建）：

```
Tests/
  └── Resources/
      └── test_basketball.mp4
```

**视频要求：**
- 格式：MP4, MOV 等
- 内容：包含篮球比赛场景
- 时长：建议 1-5 分钟（测试用）
- 质量：720p 或以上

#### 2. CoreML 模型

将训练好的模型放在以下位置：

```
Tests/
  └── Resources/
      └── YourModel.mlmodelc
```

**模型要求：**
- 格式：.mlmodelc 或 .mlpackage
- 类型：目标检测模型（如 YOLOv8）
- 标签：必须包含 "basketball" 和 "person"

### 测试用例详解

#### testGoalDetectionAndClipping

完整的进球检测和自动剪辑测试。

**测试流程：**
1. 加载测试视频和模型
2. 配置推理、分析和剪辑参数
3. 开始视频分析
4. 监听事件和剪辑创建
5. 验证结果

**验证内容：**
- ✅ 检测到至少一个事件
- ✅ 有日志输出
- ✅ 如果检测到进球，应创建剪辑
- ✅ 剪辑文件存在且大小 > 0

**预期输出：**
```
🚀 开始分析视频: test_basketball.mp4
📝 日志: 开始校准...
⏳ 进度: 10%
⏳ 进度: 20%
⚽️ 检测到进球！时间: 45.2秒
🎬 剪辑创建成功:
   索引: 1
   时间戳: 45.2秒
   时长: 8.0秒
   文件大小: 2048KB
   路径: /tmp/.../highlight_001.mp4
✅ 分析完成:
   总帧数: 300
   处理时长: 10.0秒
   平均FPS: 30.0
   检测到的事件数: 1

📊 测试总结:
   检测到的事件: 3
   进球事件: 1
   创建的剪辑: 1
   日志条数: 150
```

#### testGoalDetectionOnly

只进行进球检测，不创建剪辑。

**适用场景：**
- 快速预览检测效果
- 只需要进球时间点
- 节省存储空间

**预期输出：**
```
⚽️ 进球时间: 45.2秒
⚽️ 进球时间: 128.5秒
✅ 检测完成，共发现 2 个进球
进球 1: 45.2秒
进球 2: 128.5秒
```

#### testCustomClipConfiguration

测试自定义剪辑配置。

**测试内容：**
- 自定义前后时间（10秒 + 5秒）
- 验证剪辑时长正确
- 测试并发导出

## 🔧 跳过测试

如果没有测试数据，测试会自动跳过：

```swift
guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
    throw XCTSkip("测试视频不存在，跳过测试")
}
```

这不会导致测试失败，只是跳过该测试。

## 📊 测试覆盖率

当前测试覆盖的功能：

- ✅ 数据模型（BoundingBox, DetectedObject, AnalysisEvent）
- ✅ 配置类（InferenceConfig, VideoAnalysisConfig, VideoClipConfig）
- ✅ 推理服务创建
- ✅ 视频分析服务创建
- ✅ 进球检测逻辑
- ✅ 视频剪辑功能
- ✅ 回调机制
- ✅ 错误处理

## 🐛 调试测试

### 启用详细日志

在测试中设置 `debugMode = true`：

```swift
var config = VideoAnalysisConfig.default
config.debugMode = true
```

### 查看测试输出

```bash
swift test 2>&1 | tee test_output.log
```

### 检查剪辑文件

测试创建的剪辑保存在：

```
/tmp/VideoAnalysisSDK_Test_Output/GoalDetectionTest/
```

可以手动查看这些文件验证剪辑质量。

## 💡 编写新测试

### 测试模板

```swift
func testYourFeature() throws {
    // 1. 准备测试数据
    let testVideoURL = createTestVideoURL()
    
    // 2. 跳过测试如果没有数据
    guard FileManager.default.fileExists(atPath: testVideoURL.path) else {
        throw XCTSkip("测试数据不存在")
    }
    
    // 3. 配置 SDK
    let config = VideoAnalysisConfig.default
    let mockModel = try createMockMLModel()
    let service = VideoAnalysisSDK.createVideoAnalysisService(
        model: mockModel,
        config: config
    )
    
    // 4. 创建期望
    let expectation = expectation(description: "测试完成")
    
    // 5. 配置回调
    let callbacks = VideoAnalysisCallbacks(
        onCompletion: { result in
            // 验证结果
            XCTAssertTrue(result.totalFrames > 0)
            expectation.fulfill()
        }
    )
    
    // 6. 执行测试
    service.startAnalysis(videoURL: testVideoURL, callbacks: callbacks)
    
    // 7. 等待完成
    wait(for: [expectation], timeout: 300)
}
```

## 📚 相关文档

- [快速开始指南](../QUICK_START_GOAL_DETECTION.md)
- [示例代码](../Examples/GoalDetectionExample.swift)
- [API 文档](../README.md)

## ❓ 常见问题

### Q: 测试超时怎么办？

A: 增加超时时间或使用更短的测试视频：

```swift
wait(for: [expectation], timeout: 600)  // 增加到10分钟
```

### Q: 如何模拟不同的检测结果？

A: 可以创建自定义的 Mock 推理服务：

```swift
class MockInferenceService: InferenceServiceProtocol {
    func performInference(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> [DetectedObject] {
        // 返回模拟的检测结果
        return [
            DetectedObject(label: "basketball", confidence: 0.9, ...)
        ]
    }
}
```

### Q: 测试失败如何调试？

A: 
1. 检查测试输出日志
2. 验证测试数据是否正确
3. 启用 debugMode 查看详细信息
4. 手动运行示例代码验证功能

## 🎯 持续集成

### GitHub Actions 示例

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: swift test
```

注意：CI 环境中可能没有测试视频和模型，集成测试会被跳过。

## 📈 性能测试

可以添加性能测试来监控处理速度：

```swift
func testPerformance() throws {
    measure {
        // 测试代码
    }
}
```

## 🔒 测试最佳实践

1. **隔离性**: 每个测试应该独立运行
2. **可重复性**: 测试结果应该一致
3. **清理**: 测试后清理临时文件
4. **快速**: 单元测试应该快速完成
5. **有意义**: 测试应该验证实际功能

---

Happy Testing! 🎉
