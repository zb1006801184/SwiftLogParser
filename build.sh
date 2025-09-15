#!/bin/bash

# SwiftLogParser 打包脚本
# 用于构建和打包 SwiftUI Mac 应用

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="LogParser"
SCHEME_NAME="LogParser"
BUNDLE_ID="com.log.parser.LogParser"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/LogParser.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Export"
DMG_PATH="${BUILD_DIR}/LogParser.dmg"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查必要工具
check_requirements() {
    if ! command -v xcodebuild &> /dev/null; then
        print_message $RED "错误: 未找到 xcodebuild 命令"
        exit 1
    fi
    
    if ! command -v xcrun &> /dev/null; then
        print_message $RED "错误: 未找到 xcrun 命令"
        exit 1
    fi
}

# 清理之前的构建
clean_build() {
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    mkdir -p "$BUILD_DIR"
}

# 构建项目
build_project() {
    print_message $BLUE "开始构建项目..."
    
    xcodebuild clean \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -quiet
    
    xcodebuild archive \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM=23X3L39LGH \
        -quiet
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✓ 项目构建成功"
    else
        print_message $RED "✗ 项目构建失败"
        exit 1
    fi
}

# 导出应用
export_app() {
    print_message $BLUE "导出应用..."
    
    # 创建导出选项 plist 文件
    cat > "${BUILD_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>23X3L39LGH</string>
    <key>compileBitcode</key>
    <false/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" \
        -quiet
    
    if [ $? -eq 0 ]; then
        print_message $GREEN "✓ 应用导出成功"
        
        # 验证应用签名
        local app_path="${EXPORT_PATH}/${PROJECT_NAME}.app"
        if [ -d "$app_path" ]; then
            local signature=$(codesign -dv --verbose=4 "$app_path" 2>&1 | grep "Authority" || echo "未签名")
            if [[ $signature == *"Authority"* ]]; then
                print_message $GREEN "✓ 应用签名验证通过"
            else
                print_message $YELLOW "⚠ 应用未签名，可能影响安装"
            fi
        fi
    else
        print_message $RED "✗ 应用导出失败"
        exit 1
    fi
}

# 创建 DMG 文件
create_dmg() {
    print_message $BLUE "创建 DMG 安装包..."
    
    local app_path="${EXPORT_PATH}/${PROJECT_NAME}.app"
    local temp_dmg="${BUILD_DIR}/temp.dmg"
    local temp_mount="/tmp/${PROJECT_NAME}_dmg"
    
    if [ ! -d "$app_path" ]; then
        print_message $RED "错误: 未找到导出的应用文件"
        exit 1
    fi
    
    # 计算 DMG 大小
    local app_size=$(du -sm "$app_path" | cut -f1)
    local dmg_size=$((app_size + 100))  # 额外 100MB 空间
    
    # 创建临时目录
    mkdir -p "$temp_mount"
    
    # 复制应用到临时目录
    cp -R "$app_path" "$temp_mount/"
    
    # 创建应用程序快捷方式
    ln -s /Applications "$temp_mount/Applications"
    
    # 设置 DMG 背景和图标（可选）
    # 这里可以添加自定义背景图片和图标设置
    
    # 创建 DMG
    hdiutil create -volname "$PROJECT_NAME" -srcfolder "$temp_mount" -ov -format UDZO "$DMG_PATH" -quiet
    
    # 清理临时文件
    rm -rf "$temp_mount"
    
    # 验证 DMG 文件
    if [ -f "$DMG_PATH" ]; then
        # 测试 DMG 是否可以正常挂载
        local test_mount=$(hdiutil attach "$DMG_PATH" -nobrowse -noverify -noautoopen | grep -E '^/dev/' | sed 1q | awk '{print $3}')
        if [ -n "$test_mount" ]; then
            hdiutil detach "$test_mount" -quiet
            print_message $GREEN "✓ DMG 创建成功: $DMG_PATH"
        else
            print_message $RED "✗ DMG 文件损坏"
            exit 1
        fi
    else
        print_message $RED "✗ DMG 创建失败"
        exit 1
    fi
}

# 显示构建信息
show_build_info() {
    print_message $GREEN "\n=== 构建完成 ==="
    print_message $BLUE "应用文件: ${EXPORT_PATH}/${PROJECT_NAME}.app"
    print_message $BLUE "DMG 文件: $DMG_PATH"
    
    if [ -f "$DMG_PATH" ]; then
        local dmg_size=$(du -h "$DMG_PATH" | cut -f1)
        print_message $BLUE "DMG 大小: $dmg_size"
    fi
    
    print_message $GREEN "构建完成！"
}

# 主函数
main() {
    print_message $GREEN "开始构建 LogParser..."
    
    check_requirements
    clean_build
    build_project
    export_app
    create_dmg
    show_build_info
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
