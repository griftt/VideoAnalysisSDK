#!/bin/bash

# VideoAnalysisSDK XCFramework 构建脚本
# 用途：将 SDK 打包成 XCFramework 格式，支持 iOS、iOS Simulator 和 macOS

set -e  # 遇到错误立即退出

# ============ 配置 ============
FRAMEWORK_NAME="VideoAnalysisSDK"
OUTPUT_DIR="./build"
XCFRAMEWORK_PATH="${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
SCHEME="${FRAMEWORK_NAME}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============ 函数 ============

print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}❌ 错误: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============ 主流程 ============

print_step "开始构建 ${FRAMEWORK_NAME} XCFramework"

# 1. 清理旧文件
print_step "清理旧构建文件..."
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"
print_success "清理完成"

# 2. 构建 iOS 设备版本 (arm64)
print_step "构建 iOS (arm64)..."
xcodebuild archive \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS" \
    -archivePath "${OUTPUT_DIR}/ios-arm64" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    || exit 1
print_success "iOS 构建完成"

# 3. 构建 iOS 模拟器版本 (arm64 + x86_64)
print_step "构建 iOS Simulator (arm64 + x86_64)..."
xcodebuild archive \
    -scheme "${SCHEME}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${OUTPUT_DIR}/ios-simulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    || exit 1
print_success "iOS Simulator 构建完成"

# 4. 构建 macOS 版本 (arm64 + x86_64)
print_step "构建 macOS (arm64 + x86_64)..."
xcodebuild archive \
    -scheme "${SCHEME}" \
    -destination "generic/platform=macOS" \
    -archivePath "${OUTPUT_DIR}/macos" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    || exit 1
print_success "macOS 构建完成"

# 5. 创建 XCFramework
print_step "创建 XCFramework..."
xcodebuild -create-xcframework \
    -framework "${OUTPUT_DIR}/ios-arm64.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${OUTPUT_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${OUTPUT_DIR}/macos.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${XCFRAMEWORK_PATH}" \
    || exit 1
print_success "XCFramework 创建完成"

# 6. 创建压缩包
print_step "创建压缩包..."
cd "${OUTPUT_DIR}"
zip -r -q "${FRAMEWORK_NAME}.xcframework.zip" "${FRAMEWORK_NAME}.xcframework"
cd ..
print_success "压缩包创建完成"

# 7. 计算校验和
print_step "计算 SHA256 校验和..."
CHECKSUM=$(shasum -a 256 "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip" | awk '{print $1}')
echo "${CHECKSUM}" > "${OUTPUT_DIR}/checksum.txt"
print_success "校验和: ${CHECKSUM}"

# 8. 显示文件信息
print_step "构建信息"
echo ""
echo "📦 XCFramework 路径:"
echo "   ${XCFRAMEWORK_PATH}"
echo ""
echo "🗜️  压缩包路径:"
echo "   ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
echo ""
echo "📊 文件大小:"
du -h "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
echo ""
echo "🔐 SHA256 校验和:"
echo "   ${CHECKSUM}"
echo ""

# 9. 生成 Package.swift 示例
print_step "生成 Package.swift 示例..."
cat > "${OUTPUT_DIR}/Package.swift.example" << EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "${FRAMEWORK_NAME}",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "${FRAMEWORK_NAME}",
            targets: ["${FRAMEWORK_NAME}"]),
    ],
    targets: [
        .binaryTarget(
            name: "${FRAMEWORK_NAME}",
            url: "https://github.com/yourusername/${FRAMEWORK_NAME}/releases/download/1.0.0/${FRAMEWORK_NAME}.xcframework.zip",
            checksum: "${CHECKSUM}"
        )
    ]
)
EOF
print_success "Package.swift 示例已生成"

# 10. 完成
echo ""
print_success "🎉 构建完成！"
echo ""
print_warning "下一步："
echo "1. 将 ${FRAMEWORK_NAME}.xcframework.zip 上传到 GitHub Releases"
echo "2. 更新 Package.swift 中的 url 和 checksum"
echo "3. 创建 Git 标签并推送"
echo ""
echo "示例命令："
echo "  git tag 1.0.0"
echo "  git push origin 1.0.0"
echo "  gh release create 1.0.0 ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework.zip"
echo ""
