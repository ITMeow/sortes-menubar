# Ice 开发指南

本文档说明如何使用 Xcode 来运行和调试 Ice 项目。

## 环境要求

- **macOS 14.0 (Sonoma)** 或更高版本
- **Xcode 15.0** 或更高版本
- **Swift** 工具链 (随 Xcode 安装)

## 快速开始

### 第一步：打开项目

双击项目根目录中的 `Ice.xcodeproj` 文件，或在终端运行：

```bash
open Ice.xcodeproj
```

### 第二步：配置签名

首次打开项目时，需要配置代码签名：

1. 在 Xcode 左侧项目导航器中点击 **Ice** 项目（蓝色图标）
2. 在中间面板选择 **Ice** target
3. 点击 **Signing & Capabilities** 选项卡
4. 在 **Team** 下拉菜单中选择你的 Apple ID 或开发者团队
5. 确保 **Automatically manage signing** 已勾选

> 如果没有 Apple ID，可以在 Xcode 菜单 → Settings → Accounts 中添加。

### 第三步：选择运行目标

在 Xcode 工具栏中间的 Scheme 选择器中：

1. 确保选择的 Scheme 是 **Ice**
2. 运行目标选择 **My Mac**

### 第四步：构建并运行

- 按 **⌘R** (Command + R) 构建并运行项目
- 或者点击工具栏左上角的 **▶ 播放按钮**

首次构建可能需要几分钟时间。

## Xcode 常用快捷键

| 快捷键 | 功能 |
|--------|------|
| ⌘R | 构建并运行 |
| ⌘B | 仅构建 |
| ⌘. | 停止运行 |
| ⌘⇧K | 清理构建缓存 |
| ⌘⇧B | 分析构建 |

## 调试

### 设置断点

1. 在代码编辑器中，点击行号左侧的灰色区域
2. 出现蓝色箭头表示断点已设置
3. 再次点击可以禁用或删除断点

### 使用调试面板

当程序在断点处暂停时：

- **继续执行**：点击调试栏的 ▶ 按钮或按 ⌃⌘Y
- **单步跳过**：按 F6
- **单步进入**：按 F7
- **单步跳出**：按 F8

### 查看变量

在调试区域（底部面板）中：

- **Variables View**（左侧）：显示当前作用域的变量
- **Console**（右侧）：显示日志输出，可以输入 LLDB 命令

### 查看应用日志

Ice 使用 `Logger` 进行日志记录。查看日志的方法：

**方法一：Xcode Console**
- 运行应用时，日志会显示在 Xcode 底部的 Console 面板

**方法二：Console.app**
1. 打开 /Applications/Utilities/Console.app
2. 在左侧选择你的 Mac
3. 在搜索框中输入 "Ice" 过滤日志

## 项目结构

```
Ice.xcodeproj          # Xcode 项目文件
Ice/
├── Main/              # 应用入口和核心状态
│   ├── IceApp.swift   # @main 入口点
│   ├── AppState.swift # 全局状态管理
│   └── AppDelegate.swift
├── MenuBar/           # 菜单栏管理核心逻辑
│   ├── MenuBarManager.swift
│   ├── MenuBarSection.swift
│   └── MenuBarItems/
├── UI/                # 用户界面组件
│   ├── IceBar/        # Ice Bar 浮动面板
│   ├── LayoutBar/     # 拖放布局界面
│   └── IceUI/         # 可复用 SwiftUI 组件
├── Settings/          # 设置界面
├── Permissions/       # 权限管理
├── Hotkeys/           # 快捷键功能
├── Bridging/          # macOS 私有 API 桥接
└── Utilities/         # 工具类和扩展
```

## 权限设置

Ice 运行时需要以下系统权限：

### 辅助功能权限（必需）

1. 首次运行时会自动弹出权限请求
2. 或者手动设置：**系统设置** → **隐私与安全性** → **辅助功能**
3. 找到 Ice（或 Xcode）并勾选

### 屏幕录制权限（推荐）

1. **系统设置** → **隐私与安全性** → **屏幕录制**
2. 找到 Ice（或 Xcode）并勾选
3. 如果图标不显示，尝试取消勾选后重新勾选

> **注意**：调试时，权限可能会关联到 Xcode 而不是 Ice.app。两者都需要授权。

## 常见问题

### 1. "Ice" 需要辅助功能权限

这是正常的权限请求。点击"打开系统设置"，然后在辅助功能列表中勾选 Ice 或 Xcode。

### 2. 菜单栏布局中图标不显示

原因是缺少屏幕录制权限：
1. 打开 **系统设置** → **隐私与安全性** → **屏幕录制**
2. 勾选 Ice 和 Xcode
3. 完全退出并重新运行应用

### 3. 构建失败："Signing for 'Ice' requires a development team"

需要配置代码签名，请参考上面的"配置签名"步骤。

### 4. SwiftLint 错误

项目使用 SwiftLint 进行代码规范检查。如果遇到 SwiftLint 相关错误：

```bash
# 安装 SwiftLint
brew install swiftlint

# 手动运行检查
swiftlint

# 自动修复部分问题
swiftlint --fix
```

## 关键调试位置

如果需要调试特定功能，建议在以下位置设置断点：

| 文件 | 函数 | 用途 |
|------|------|------|
| AppState.swift | `performSetup()` | 应用启动流程 |
| MenuBarManager.swift | `performSetup()` | 菜单栏初始化 |
| MenuBarItemImageCache.swift | `updateCache()` | 图像缓存更新 |
| ScreenCapture.swift | `checkPermissions()` | 权限检查 |
| IceBar.swift | `show(section:on:)` | Ice Bar 显示逻辑 |

## 构建配置

项目包含两个构建配置：

- **Debug**：用于开发和调试，包含调试符号，未优化
- **Release**：用于发布，已优化，不包含调试符号

切换配置：**Product** → **Scheme** → **Edit Scheme** → **Run** → **Build Configuration**

## 联系方式

如有问题，请在 GitHub 仓库提交 Issue：
https://github.com/jordanbaird/Ice/issues
