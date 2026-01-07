# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码仓库中工作时提供指导。

## 项目概述

SortBar 是一款 macOS 菜单栏管理工具，支持隐藏/显示菜单栏项目并提供额外的自定义功能。这是一个原生 Swift 应用，需要 macOS 14+。

## 构建命令

- **构建**: 在 Xcode 中打开 `SortBar.xcodeproj` 并构建 (Cmd+B)
- **运行**: 在 Xcode 中构建并运行 (Cmd+R)
- **代码检查**: `swiftlint --strict` (作为 Xcode 构建阶段和 CI 中自动运行)

## 架构

### 核心模式
应用使用集中式的 `AppState` (@MainActor ObservableObject) 来持有所有管理器，并通过 SwiftUI 环境传递。入口点是 `SortBarApp.swift`，它创建 AppState 并将其传递给 AppDelegate。

### 核心管理器 (均在 AppState 中)
- **MenuBarManager**: 管理菜单栏分区（可见、隐藏、始终隐藏）和 SortBar Bar 面板
- **MenuBarItemManager**: 跟踪和缓存系统中的菜单栏项目
- **AppearanceManager**: 处理菜单栏自定义（色调、阴影、边框、形状）
- **EventManager**: 集中处理鼠标、键盘和系统事件
- **PermissionsManager**: 管理辅助功能和屏幕录制权限
- **SettingsManager**: 通过 `@AppStorage` 和子管理器持久化用户偏好设置

### 菜单栏分区
三个 `MenuBarSection` 实例代表：
- `.visible` - 始终显示的项目
- `.hidden` - 隐藏在 SortBar 图标后面的项目
- `.alwaysHidden` - 除非明确显示否则永不显示的项目

每个分区都有一个 `ControlItem`（菜单栏中的分隔图标）。

### 私有 API (SortBar/Bridging/)
应用使用私有 macOS API 访问窗口服务器：
- `Bridging.swift` - 桥接功能的高级命名空间
- `Private.swift` - CGS 函数声明 (`@_silgen_name`)
- `Deprecated.swift` - 已弃用的 API 垫片

关键私有 API: `CGSMainConnectionID`, `CGSGetWindowList`, `CGSGetActiveSpace`, `CGSSpaceGetType`

### UI 组件
- **SortBarBar** (`SortBar/UI/SortBarBar/`): 显示隐藏菜单栏项目的浮动面板
- **LayoutBar** (`SortBar/UI/LayoutBar/`): 用于重新排列项目的拖放界面
- **SortBarUI** (`SortBar/UI/SortBarUI/`): 以 "SortBar" 为前缀的可复用 SwiftUI 组件

## 代码风格

- 使用 SwiftLint 强制执行自定义规则（见 `.swiftlint.yml`）
- 4 空格缩进（禁止使用 Tab）
- 需要文件头: `// [文件名] // SortBar //`
- 多行集合中必须使用尾随逗号
- 基于分类的 Logger 扩展模式: `private extension Logger { static let foo = Logger(category: "Foo") }`
- 管理器遵循 `BindingExposable` 协议以便于 SwiftUI 绑定

## 依赖项 (Swift Package Manager)

- **AXSwift**: 辅助功能 API 封装
- **Sparkle**: 自动更新
- **LaunchAtLogin**: 登录项管理
- **CompactSlider**: 自定义滑块 UI
- **IfritStatic**: 静态分析工具
