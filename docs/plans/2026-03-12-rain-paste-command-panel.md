# RainPaste Command Panel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 RainPaste 主界面改造成更紧凑的浮层命令面板，并把默认快捷键调整为 `⌘⇧V`，支持 `Esc` 关闭。

**Architecture:** 保持现有 `SwiftUI + AppKit` 结构不变，使用窗口协调器统一配置无标题栏面板，在视图模型中增加关闭动作回调，并通过状态栏承担管理功能。主界面收敛为单栏列表视图，减少面板尺寸与视觉噪声。

**Tech Stack:** Swift 6、SwiftUI、AppKit、XCTest、Swift Package Manager

---

### Task 1: 更新快捷键默认值与行为测试

**Files:**
- Modify: `Sources/RainPasteApp/Services/GlobalHotKeyService.swift`
- Modify: `Tests/RainPasteAppTests/Services/GlobalHotKeyServiceTests.swift`

**Step 1: Write the failing test**

```swift
func testDefaultShortcutFormatsForDisplay() {
    let shortcut = GlobalShortcut.defaultValue
    XCTAssertEqual(shortcut.displayLabel, "⌘⇧V")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter GlobalHotKeyServiceTests`
Expected: FAIL because current label is `⌘⌥V`

**Step 3: Write minimal implementation**

```swift
static let defaultValue = GlobalShortcut(
    keyCode: UInt32(kVK_ANSI_V),
    modifiers: [.command, .shift]
)
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter GlobalHotKeyServiceTests`
Expected: PASS

### Task 2: 为面板关闭能力补测试并接入视图模型

**Files:**
- Modify: `Sources/RainPasteApp/ViewModels/AppViewModel.swift`
- Modify: `Sources/RainPasteApp/AppBootstrap.swift`
- Modify: `Tests/RainPasteAppTests/ViewModels/AppViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testCloseTriggersDismissAction() {
    var didClose = false
    let viewModel = AppViewModel(..., onClose: { didClose = true })
    viewModel.closePanel()
    XCTAssertTrue(didClose)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppViewModelTests`
Expected: FAIL because close action does not exist

**Step 3: Write minimal implementation**

```swift
private let onClose: () -> Void

func closePanel() {
    onClose()
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppViewModelTests`
Expected: PASS

### Task 3: 将主界面改成单栏命令面板

**Files:**
- Modify: `Sources/RainPasteApp/Views/MainWindowView.swift`
- Modify: `Sources/RainPasteApp/Views/ClipboardRowView.swift`

**Step 1: Write the failing test**

本任务主要是界面重构，使用构建验证代替视图级单测。

**Step 2: Run test to verify it fails**

Run: `swift build`
Expected: PASS before changes, then use it as compilation guard after重构

**Step 3: Write minimal implementation**

至少完成：
- 删除右侧控制面板
- 缩小整体尺寸
- 增加底部状态条
- 为视图添加 `Esc` 关闭处理

**Step 4: Run build to verify it passes**

Run: `swift build`
Expected: PASS

### Task 4: 将窗口改成无标题栏浮层并重新打包

**Files:**
- Modify: `Sources/RainPasteApp/Windowing/MainWindowCoordinator.swift`
- Modify: `RainPaste.app/Contents/Info.plist`

**Step 1: Write the failing test**

本任务主要是窗口装配与打包，使用构建与包校验代替单测。

**Step 2: Run build to establish baseline**

Run: `swift build`
Expected: PASS

**Step 3: Write minimal implementation**

至少完成：
- 隐藏标题栏与窗口按钮
- 缩小默认尺寸
- 设置更适合面板的层级与行为
- 重新复制二进制到 `.app`

**Step 4: Run verification**

Run: `swift test`
Expected: PASS

Run: `swift build -c release`
Expected: PASS

Run: `plutil -lint RainPaste.app/Contents/Info.plist`
Expected: OK
