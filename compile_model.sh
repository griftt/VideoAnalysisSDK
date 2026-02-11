#!/bin/bash

# 编译 CoreML 模型脚本

set -e

# 模型路径
MODEL_PACKAGE="/Users/grifftwu/Desktop/VideoAnalysisSDK/best.mlpackage"
OUTPUT_DIR="/Users/grifftwu/Desktop/VideoAnalysisSDK"

echo "========================================"
echo "编译 CoreML 模型"
echo "========================================"
echo ""

# 验证模型文件存在
if [ ! -e "$MODEL_PACKAGE" ]; then
    echo "❌ 模型文件不存在:"
    echo "   $MODEL_PACKAGE"
    exit 1
fi

echo "✅ 找到模型文件:"
echo "   $MODEL_PACKAGE"
echo ""

# 编译模型
echo "🔨 正在编译模型..."
echo ""

xcrun coremlcompiler compile "$MODEL_PACKAGE" "$OUTPUT_DIR"

# 检查编译结果
COMPILED_MODEL="$OUTPUT_DIR/best.mlmodelc"

if [ -e "$COMPILED_MODEL" ]; then
    echo ""
    echo "✅ 模型编译成功！"
    echo "   输出: $COMPILED_MODEL"
    echo ""
    
    # 显示文件大小
    echo "📊 文件信息:"
    du -sh "$MODEL_PACKAGE" | awk '{print "   原始模型: " $1}'
    du -sh "$COMPILED_MODEL" | awk '{print "   编译后: " $1}'
    echo ""
    
    echo "✅ 现在可以运行测试了："
    echo "   ./test.sh"
else
    echo ""
    echo "❌ 模型编译失败"
    exit 1
fi
