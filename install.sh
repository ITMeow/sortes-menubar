#!/bin/bash

# 设置变量
PROJECT_NAME="SortBar"
SCHEME_NAME="SortBar"
APP_NAME="SortBar.app"
INSTALL_DIR="/Applications"
BUILD_DIR="./build"

# 1. 清理并构建
echo "🚀 开始构建 $PROJECT_NAME (Release)..."
xcodebuild -project "$PROJECT_NAME.xcodeproj" \
           -scheme "$SCHEME_NAME" \
           -configuration Release \
           -derivedDataPath "$BUILD_DIR" \
           clean build -quiet

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo "❌ 构建失败。"
    exit 1
fi

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME"

# 检查生成的 App 是否存在
if [ ! -d "$BUILT_APP" ]; then
    echo "❌ 未找到构建好的 App: $BUILT_APP"
    exit 1
fi

echo "✅ 构建成功！"

# 2. 安装 (替换旧版本)
INSTALLED_APP="$INSTALL_DIR/$APP_NAME"

echo "📦 正在安装到 $INSTALL_DIR..."

if [ -d "$INSTALLED_APP" ]; then
    echo "🗑️  发现旧版本，正在删除..."
    rm -rf "$INSTALLED_APP"
fi

echo "🚚 正在复制新版本..."
cp -R "$BUILT_APP" "$INSTALL_DIR"

# 3. 清理构建缓存 (可选)
# rm -rf "$BUILD_DIR"

echo "🎉 升级完成！请在应用程序文件夹中启动 $PROJECT_NAME。"
