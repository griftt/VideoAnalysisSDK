#!/bin/bash

# VideoAnalysisSDK 自动发布脚本
# 用途：自动化版本发布流程

set -e  # 遇到错误立即退出

# ============ 配置 ============
FRAMEWORK_NAME="VideoAnalysisSDK"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============ 函数 ============

print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}❌ 错误: $1${NC}"
    exit 1
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============ 参数检查 ============

VERSION=$1

if [ -z "$VERSION" ]; then
    print_error "请提供版本号\n用法: ./release.sh <version>\n示例: ./release.sh 1.0.0"
fi

# 验证版本号格式 (x.y.z)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "版本号格式错误，应为 x.y.z (如 1.0.0)"
fi

# ============ 主流程 ============

echo ""
print_step "🚀 开始发布 ${FRAMEWORK_NAME} v${VERSION}"
echo ""

# 1. 检查工作目录是否干净
print_step "检查 Git 状态..."
if [[ -n $(git status -s) ]]; then
    print_warning "工作目录有未提交的更改"
    git status -s
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "发布已取消"
    fi
fi
print_success "Git 状态检查完成"

# 2. 检查是否在 main/master 分支
print_step "检查当前分支..."
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
    print_warning "当前分支: ${CURRENT_BRANCH}"
    read -p "建议在 main/master 分支发布，是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "发布已取消"
    fi
fi
print_success "分支检查完成"

# 3. 拉取最新代码
print_step "拉取最新代码..."
git pull origin "${CURRENT_BRANCH}" || print_warning "拉取失败，继续..."
print_success "代码已更新"

# 4. 运行测试
print_step "运行测试..."
if command -v swift &> /dev/null; then
    swift test || print_error "测试失败，请修复后再发布"
    print_success "所有测试通过"
else
    print_warning "未找到 swift 命令，跳过测试"
fi

# 5. 更新 CHANGELOG
print_step "更新 CHANGELOG.md..."
if [ ! -f "CHANGELOG.md" ]; then
    cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [${VERSION}] - $(date +%Y-%m-%d)

### Added
- Initial release

EOF
    print_success "CHANGELOG.md 已创建"
else
    print_warning "CHANGELOG.md 已存在，请手动更新版本信息"
    read -p "按回车继续..."
fi

# 6. 提交版本变更
print_step "提交版本变更..."
git add .
git commit -m "Release v${VERSION}" || print_warning "没有需要提交的更改"
print_success "变更已提交"

# 7. 创建标签
print_step "创建 Git 标签..."
if git tag -l | grep -q "^${VERSION}$"; then
    print_warning "标签 ${VERSION} 已存在"
    read -p "是否删除并重新创建？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "${VERSION}"
        git push origin ":refs/tags/${VERSION}" 2>/dev/null || true
    else
        print_error "发布已取消"
    fi
fi
git tag -a "${VERSION}" -m "Release v${VERSION}"
print_success "标签已创建"

# 8. 推送到远程
print_step "推送到远程仓库..."
git push origin "${CURRENT_BRANCH}"
git push origin "${VERSION}"
print_success "代码已推送"

# 9. 构建 XCFramework
print_step "构建 XCFramework..."
if [ -f "build_xcframework.sh" ]; then
    chmod +x build_xcframework.sh
    ./build_xcframework.sh
    print_success "XCFramework 构建完成"
else
    print_warning "未找到 build_xcframework.sh，跳过构建"
fi

# 10. 创建 GitHub Release
print_step "创建 GitHub Release..."
if command -v gh &> /dev/null; then
    RELEASE_NOTES="See [CHANGELOG.md](CHANGELOG.md) for details."
    
    if [ -f "build/${FRAMEWORK_NAME}.xcframework.zip" ]; then
        gh release create "${VERSION}" \
            "build/${FRAMEWORK_NAME}.xcframework.zip" \
            --title "v${VERSION}" \
            --notes "${RELEASE_NOTES}"
    else
        gh release create "${VERSION}" \
            --title "v${VERSION}" \
            --notes "${RELEASE_NOTES}"
    fi
    print_success "GitHub Release 已创建"
else
    print_warning "未找到 gh 命令，请手动创建 GitHub Release"
    echo "访问: https://github.com/yourusername/${FRAMEWORK_NAME}/releases/new"
fi

# 11. 发布到 CocoaPods（可选）
if [ -f "${FRAMEWORK_NAME}.podspec" ]; then
    print_step "发布到 CocoaPods..."
    read -p "是否发布到 CocoaPods？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v pod &> /dev/null; then
            pod trunk push "${FRAMEWORK_NAME}.podspec" --allow-warnings
            print_success "已发布到 CocoaPods"
        else
            print_warning "未找到 pod 命令"
        fi
    fi
fi

# 12. 完成
echo ""
print_success "🎉 发布完成！"
echo ""
echo "📦 版本: v${VERSION}"
echo "🏷️  标签: ${VERSION}"
echo "🌐 GitHub: https://github.com/yourusername/${FRAMEWORK_NAME}/releases/tag/${VERSION}"
echo ""
print_warning "下一步："
echo "1. 检查 GitHub Release 是否正确"
echo "2. 更新文档和示例"
echo "3. 通知用户新版本发布"
echo ""
