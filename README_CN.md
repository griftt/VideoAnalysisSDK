# VideoAnalysisSDK - 快速开始

## 🚀 一键运行测试

```bash
cd VideoAnalysisSDK
./test.sh
```

就这么简单！

## 📋 测试配置

### 固定路径
- **视频**: `/Users/grifftwu/Desktop/历史篮球/20260205/mine.MP4`
- **模型**: `/Users/grifftwu/Desktop/VideoAnalysisSDK/best.mlpackage`
- **输出**: `~/Desktop/BasketballClips`

### 配置参数（与 HighlightMoment 相同）
- 置信度阈值: 0.15
- 跳帧数: 3
- 校准帧数: 30
- 事件窗口: 2.5秒
- 剪辑前置: 4秒，后置: 2秒

## 📊 测试流程

```
1. 验证文件 ✓
2. 加载模型 ✓
3. 校准篮筐（30帧）
4. 检测进球
5. 生成剪辑
6. 输出结果 ✓
```

## 🎬 输出结果

剪辑文件保存在：
```
~/Desktop/BasketballClips/Test_<时间戳>/
├── highlight_001.mp4  (第1个进球)
├── highlight_002.mp4  (第2个进球)
└── ...
```

## 🔧 自定义输出目录

```bash
./test.sh ~/Desktop/MyClips
```

## 📖 详细文档

- [MY_TEST_GUIDE.md](MY_TEST_GUIDE.md) - 详细测试指南
- [使用说明.md](使用说明.md) - 完整使用说明
- [MODEL_FORMAT_GUIDE.md](MODEL_FORMAT_GUIDE.md) - 模型格式指南

## ❓ 常见问题

### 检测不到进球？
```bash
# 开启调试模式查看详细日志
# 编辑 Examples/RunCompleteTest.swift
debugMode: true
```

### 误检太多？
```bash
# 提高置信度阈值
# 编辑 Examples/RunCompleteTest.swift
confidenceThreshold: 0.25
```

## 💡 提示

- 首次运行需要构建项目（约1-2分钟）
- 后续运行会更快
- 剪辑文件会自动保存到桌面

---

**立即开始:**
```bash
cd VideoAnalysisSDK
./test.sh
```

🎉 祝测试顺利！
