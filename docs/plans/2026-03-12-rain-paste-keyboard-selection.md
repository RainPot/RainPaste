# RainPaste Keyboard Selection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 RainPaste 命令面板增加默认选中、上下切换与回车粘贴的键盘交互。

**Architecture:** 在 `AppViewModel` 中集中管理当前选中项与导航行为，在窗口层拦截键盘事件并分发给视图模型，视图层只负责高亮和滚动到当前选中项。这样可以保证搜索框有焦点时键盘导航仍然稳定可用。

**Tech Stack:** Swift 6、SwiftUI、AppKit、XCTest、Swift Package Manager

---

### Task 1: 为选中状态与导航行为补测试

**Files:**
- Modify: `Tests/RainPasteAppTests/ViewModels/AppViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testInitialSelectionDefaultsToFirstItem() { ... }
func testMoveSelectionDownAndUp() { ... }
func testActivateSelectionCopiesSelectedItem() { ... }
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppViewModelTests`
Expected: FAIL because selection APIs do not exist

**Step 3: Write minimal implementation**

```swift
@Published private(set) var selectedItemID: UUID?

func moveSelection(delta: Int) { ... }
func activateSelectedItem() { ... }
func prepareForPresentation() { ... }
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppViewModelTests`
Expected: PASS

### Task 2: 接入窗口层按键分发

**Files:**
- Modify: `Sources/RainPasteApp/Windowing/MainWindowCoordinator.swift`
- Modify: `Sources/RainPasteApp/AppBootstrap.swift`

**Step 1: Write the failing test**

本任务用现有视图模型测试和编译验证作为保护网。

**Step 2: Run build to verify baseline**

Run: `swift build`
Expected: PASS

**Step 3: Write minimal implementation**

至少完成：
- 拦截 `↑ / ↓ / Enter / Esc`
- 调用 `moveSelection(delta:)` 与 `activateSelectedItem()`
- 每次显示窗口时重置默认选中

**Step 4: Run build to verify it passes**

Run: `swift build`
Expected: PASS

### Task 3: 更新列表高亮与滚动定位

**Files:**
- Modify: `Sources/RainPasteApp/Views/MainWindowView.swift`
- Modify: `Sources/RainPasteApp/Views/ClipboardRowView.swift`

**Step 1: Write the failing test**

本任务以构建验证代替视图单测。

**Step 2: Run build to verify baseline**

Run: `swift build`
Expected: PASS

**Step 3: Write minimal implementation**

至少完成：
- 当前选中项高亮
- 选中项变化时滚动到可见区域
- 鼠标点击时同步更新选中项

**Step 4: Run verification**

Run: `swift test`
Expected: PASS

Run: `swift build`
Expected: PASS
