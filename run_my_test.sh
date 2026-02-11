#!/bin/bash

# 固定路径测试脚本
# 视频路径: /Users/grifftwu/Desktop/历史篮球/20260205/mine.MP4
# 模型路径: /Users/grifftwu/Desktop/VideoAnalysisSDK/best.mlmodelc

set -e

# 固定路径
VIDEO_PATH="/Users/grifftwu/Desktop/历史篮球/20260205/0205.mov"
MODEL_PATH="/Users/grifftwu/Desktop/VideoAnalysisSDK/best.mlmodelc"
OUTPUT_DIR="${1:-$HOME/Desktop/BasketballClips}"

echo "========================================"
echo "VideoAnalysisSDK 测试"
echo "使用固定路径"
echo "========================================"
echo ""

# 验证文件存在
echo "📋 验证文件..."
echo ""

if [ ! -f "$VIDEO_PATH" ]; then
    echo "❌ 视频文件不存在:"
    echo "   $VIDEO_PATH"
    exit 1
fi
echo "✅ 视频文件:"
echo "   $VIDEO_PATH"
echo ""

if [ ! -e "$MODEL_PATH" ]; then
    echo "❌ 模型文件不存在:"
    echo "   $MODEL_PATH"
    exit 1
fi
echo "✅ 模型文件:"
echo "   $MODEL_PATH"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
echo "✅ 输出目录:"
echo "   $OUTPUT_DIR"
echo ""

# 构建项目
echo "🔨 构建项目..."
swift build
echo "✅ 构建完成"
echo ""

# 运行测试
echo "🚀 开始测试..."
echo ""

swift run CompleteTest "$VIDEO_PATH" "$MODEL_PATH" "$OUTPUT_DIR"

echo ""
echo "✅ 测试完成！"
echo "📁 剪辑文件保存在: $OUTPUT_DIR"
