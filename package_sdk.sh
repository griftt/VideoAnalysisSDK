#!/bin/bash

# VideoAnalysisSDK 简易打包脚本
# 用途：使用 Swift Package Manager 构建并打包 SDK

set -e

# 配置
FRAMEWORK_NAME="VideoAnalysisSDK"
OUTPUT_DIR="./build"
VERSION="${1:-1.0.0}"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==>${NC} ${GREEN}开始打包 ${FRAMEWORK_NAME}${NC}"
echo ""

# 1. 清理旧文件
echo -e "${BLUE}==>${NC} 清理旧构建文件..."
rm -rf "${OUTPUT_DIR}"
rm -rf .build
mkdir -p "${OUTPUT_DIR}"

# 2. 构建 Release 版本
echo -e "${BLUE}==>${NC} 构建 Release 版本..."
swift build -c release --arch arm64 --arch x86_64

# 3. 复制构建产物
echo -e "${BLUE}==>${NC} 复制构建产物..."
mkdir -p "${OUTPUT_DIR}/${FRAMEWORK_NAME}"
cp -r .build/apple/Products/Release/*.swiftmodule "${OUTPUT_DIR}/${FRAMEWORK_NAME}/"
cp .build/apple/Products/Release/*.o "${OUTPUT_DIR}/${FRAMEWORK_NAME}/"

# 4. 复制源代码
echo -e "${BLUE}==>${NC} 复制源代码..."
cp -r Sources "${OUTPUT_DIR}/${FRAMEWORK_NAME}/"
cp Package.swift "${OUTPUT_DIR}/${FRAMEWORK_NAME}/"
cp README.md "${OUTPUT_DIR}/${FRAMEWORK_NAME}/" 2>/dev/null || true
cp LICENSE "${OUTPUT_DIR}/${FRAMEWORK_NAME}/" 2>/dev/null || true

# 5. 创建压缩包
echo -e "${BLUE}==>${NC} 创建压缩包..."
cd "${OUTPUT_DIR}"
zip -r -q "${FRAMEWORK_NAME}-${VERSION}.zip" "${FRAMEWORK_NAME}"
cd ..

# 6. 计算校验和
echo -e "${BLUE}==>${NC} 计算 SHA256 校验和..."
CHECKSUM=$(shasum -a 256 "${OUTPUT_DIR}/${FRAMEWORK_NAME}-${VERSION}.zip" | awk '{print $1}')
echo "${CHECKSUM}" > "${OUTPUT_DIR}/checksum.txt"

# 7. 显示结果
echo ""
echo -e "${GREEN}✅ 打包完成！${NC}"
echo ""
echo "📦 压缩包路径: ${OUTPUT_DIR}/${FRAMEWORK_NAME}-${VERSION}.zip"
echo "📊 文件大小: $(du -h "${OUTPUT_DIR}/${FRAMEWORK_NAME}-${VERSION}.zip" | awk '{print $1}')"
echo "🔐 SHA256: ${CHECKSUM}"
echo ""
echo -e "${YELLOW}使用方法：${NC}"
echo "1. 将 ${FRAMEWORK_NAME}-${VERSION}.zip 分发给用户"
echo "2. 用户解压后，在 Package.swift 中添加本地依赖："
echo ""
echo "   .package(path: \"path/to/${FRAMEWORK_NAME}\")"
echo ""

