# RainPaste Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建一个原生 macOS 文本粘贴板工具，支持菜单栏入口、主窗口管理、全局快捷键、历史持久化与基础设置。

**Architecture:** 使用 `Swift Package` 承载 `SwiftUI` macOS 可执行应用，界面与状态管理由 `SwiftUI + ObservableObject` 负责，`AppKit` 负责菜单栏、窗口激活和全局快捷键桥接。剪贴板监听、历史存储、设置存储分别拆分成独立服务，并通过测试先行驱动核心行为。

**Tech Stack:** Swift 6、SwiftUI、AppKit、XCTest、JSON 持久化、Carbon 快捷键桥接

---

### Task 1: 初始化工程与基础模型

**Files:**
- Create: `Package.swift`
- Create: `Sources/RainPasteApp/RainPasteApp.swift`
- Create: `Sources/RainPasteApp/AppBootstrap.swift`
- Create: `Sources/RainPasteApp/Models/ClipboardItem.swift`
- Create: `Sources/RainPasteApp/Models/AppSettings.swift`
- Create: `Tests/RainPasteAppTests/Models/ClipboardItemTests.swift`
- Create: `Tests/RainPasteAppTests/Models/AppSettingsTests.swift`

**Step 1: Write the failing test**

```swift
func testPinnedItemsSortBeforeRecentItems() {
    let recent = ClipboardItem.make(content: "recent", createdAt: .now, isPinned: false)
    let pinned = ClipboardItem.make(content: "pinned", createdAt: .distantPast, isPinned: true)

    let sorted = ClipboardItem.sortForDisplay([recent, pinned])

    XCTAssertEqual(sorted.map(\.content), ["pinned", "recent"])
}
```

```swift
func testDefaultSettingsMatchProductExpectation() {
    let settings = AppSettings.defaultValue

    XCTAssertEqual(settings.maxHistoryCount, 200)
    XCTAssertTrue(settings.ignoresConsecutiveDuplicates)
    XCTAssertTrue(settings.closesWindowAfterCopy)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ClipboardItemTests`
Expected: FAIL with missing `ClipboardItem`

**Step 3: Write minimal implementation**

```swift
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let createdAt: Date
    var isPinned: Bool

    static func sortForDisplay(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.createdAt > $1.createdAt
        }
    }
}

struct AppSettings: Codable, Equatable {
    var maxHistoryCount: Int
    var ignoresConsecutiveDuplicates: Bool
    var closesWindowAfterCopy: Bool

    static let defaultValue = AppSettings(
        maxHistoryCount: 200,
        ignoresConsecutiveDuplicates: true,
        closesWindowAfterCopy: true
    )
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ClipboardItemTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Package.swift Sources/RainPasteApp Tests/RainPasteAppTests docs/plans/2026-03-12-rain-paste-design.md docs/plans/2026-03-12-rain-paste.md
git commit -m "feat: 初始化工程与基础模型"
```

### Task 2: 实现历史仓库与持久化

**Files:**
- Create: `Sources/RainPasteApp/Services/ClipboardHistoryStore.swift`
- Create: `Sources/RainPasteApp/Services/HistoryPersistence.swift`
- Create: `Tests/RainPasteAppTests/Services/ClipboardHistoryStoreTests.swift`
- Create: `Tests/RainPasteAppTests/Services/HistoryPersistenceTests.swift`

**Step 1: Write the failing test**

```swift
func testAddItemDropsOldestUnpinnedItemsBeyondLimit() throws {
    let store = ClipboardHistoryStore(settings: .init(maxHistoryCount: 2, ignoresConsecutiveDuplicates: true, closesWindowAfterCopy: true))

    store.ingest("first")
    store.ingest("second")
    store.ingest("third")

    XCTAssertEqual(store.items.map(\.content), ["third", "second"])
}
```

```swift
func testPersistenceRoundTripRestoresPinnedState() throws {
    let persistence = HistoryPersistence(fileURL: temporaryURL)
    let items = [ClipboardItem.make(content: "hello", isPinned: true)]

    try persistence.save(items: items, settings: .defaultValue)
    let snapshot = try persistence.load()

    XCTAssertEqual(snapshot.items.first?.isPinned, true)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ClipboardHistoryStoreTests`
Expected: FAIL with missing store implementation

**Step 3: Write minimal implementation**

```swift
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []

    func ingest(_ text: String) {
        // 忽略空值与连续重复，然后插入头部并按上限裁剪
    }
}
```

```swift
struct PersistedSnapshot: Codable {
    let items: [ClipboardItem]
    let settings: AppSettings
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ClipboardHistoryStoreTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/RainPasteApp/Services Tests/RainPasteAppTests/Services
git commit -m "feat: 添加历史仓库与本地持久化"
```

### Task 3: 实现剪贴板监听与复制回写

**Files:**
- Create: `Sources/RainPasteApp/Services/ClipboardMonitoring.swift`
- Create: `Sources/RainPasteApp/Services/SystemPasteboard.swift`
- Create: `Tests/RainPasteAppTests/Services/ClipboardMonitoringTests.swift`

**Step 1: Write the failing test**

```swift
func testMonitorIngestsOnlyNewClipboardText() {
    let pasteboard = FakePasteboard(changeSequence: [
        .init(changeCount: 1, text: "A"),
        .init(changeCount: 1, text: "A"),
        .init(changeCount: 2, text: "B")
    ])
    let store = ClipboardHistoryStore(settings: .defaultValue)
    let monitor = ClipboardMonitoring(pasteboard: pasteboard, store: store)

    monitor.poll()
    monitor.poll()
    monitor.poll()

    XCTAssertEqual(store.items.map(\.content), ["B", "A"])
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ClipboardMonitoringTests`
Expected: FAIL with missing monitor implementation

**Step 3: Write minimal implementation**

```swift
protocol SystemPasteboard {
    var changeCount: Int { get }
    func currentText() -> String?
    func write(text: String)
}

final class ClipboardMonitoring {
    private var lastChangeCount: Int?

    func poll() {
        // 仅在 changeCount 变化时读取文本并写入 store
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ClipboardMonitoringTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/RainPasteApp/Services Tests/RainPasteAppTests/Services
git commit -m "feat: 添加剪贴板监听与回写能力"
```

### Task 4: 实现主窗口界面与菜单栏桥接

**Files:**
- Create: `Sources/RainPasteApp/ViewModels/AppViewModel.swift`
- Create: `Sources/RainPasteApp/Views/MainWindowView.swift`
- Create: `Sources/RainPasteApp/Views/ClipboardRowView.swift`
- Create: `Sources/RainPasteApp/MenuBar/MenuBarController.swift`
- Create: `Sources/RainPasteApp/MenuBar/MenuBarContentBuilder.swift`
- Create: `Tests/RainPasteAppTests/ViewModels/AppViewModelTests.swift`

**Step 1: Write the failing test**

```swift
func testSearchReturnsPinnedAndMatchingItemsInDisplayOrder() {
    let viewModel = AppViewModel.preview(items: [
        .make(content: "npm run dev", isPinned: true),
        .make(content: "swift build", isPinned: false),
        .make(content: "git status", isPinned: false)
    ])

    viewModel.searchText = "sw"

    XCTAssertEqual(viewModel.filteredItems.map(\.content), ["swift build"])
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppViewModelTests`
Expected: FAIL with missing view model

**Step 3: Write minimal implementation**

```swift
@MainActor
final class AppViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var filteredItems: [ClipboardItem] = []

    func reload() {
        // 按搜索词过滤并输出展示顺序
    }
}
```

主窗口至少完成：
- 搜索框
- 列表展示
- 点击复制
- 置顶/删除按钮
- 清空历史按钮

菜单栏至少完成：
- 最近 8 条历史
- 打开主窗口
- 暂停监听
- 清空历史
- 退出

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/RainPasteApp/ViewModels Sources/RainPasteApp/Views Sources/RainPasteApp/MenuBar Tests/RainPasteAppTests/ViewModels
git commit -m "feat: 完成主窗口与菜单栏界面"
```

### Task 5: 实现全局快捷键、应用装配与验证

**Files:**
- Create: `Sources/RainPasteApp/Services/GlobalHotKeyService.swift`
- Modify: `Sources/RainPasteApp/AppBootstrap.swift`
- Modify: `Sources/RainPasteApp/RainPasteApp.swift`
- Create: `Tests/RainPasteAppTests/Services/GlobalHotKeyServiceTests.swift`

**Step 1: Write the failing test**

```swift
func testDefaultShortcutFormatsForDisplay() {
    let shortcut = GlobalShortcut(keyCode: kVK_ANSI_V, modifiers: [.command, .option])

    XCTAssertEqual(shortcut.displayLabel, "⌘⌥V")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter GlobalHotKeyServiceTests`
Expected: FAIL with missing shortcut type

**Step 3: Write minimal implementation**

```swift
struct GlobalShortcut: Equatable {
    let keyCode: UInt32
    let modifiers: NSEvent.ModifierFlags
}

final class GlobalHotKeyService {
    func register(_ shortcut: GlobalShortcut, handler: @escaping () -> Void) {
        // 使用 Carbon 注册事件并在触发时回调
    }
}
```

应用装配至少完成：
- 启动时载入持久化历史
- 启动剪贴板监听
- 注册默认快捷键
- 热键触发后激活并显示主窗口

**Step 4: Run test to verify it passes**

Run: `swift test --filter GlobalHotKeyServiceTests`
Expected: PASS

**Step 5: Run full verification**

Run: `swift test`
Expected: PASS

Run: `swift build`
Expected: PASS

**Step 6: Commit**

```bash
git add Sources/RainPasteApp Tests/RainPasteAppTests
git commit -m "feat: 完成全局快捷键与应用装配"
```
