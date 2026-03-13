import AppKit
import XCTest
@testable import RainPasteApp

@MainActor
final class AutoPasteServiceTests: XCTestCase {
    func testPasteActivatesCapturedTargetAndPostsCommandV() {
        let targetApp = FakeRunningApplication(bundleIdentifier: "com.apple.TextEdit")
        let provider = FakeFrontmostApplicationProvider(frontmostApplication: targetApp)
        let poster = FakePasteEventPoster(isTrustedResult: true)
        let scheduler = ImmediateEventScheduler()
        let focusManager = NullFocusStateManager()
        let service = AutoPasteService(
            applicationProvider: provider,
            focusStateManager: focusManager,
            eventPoster: poster,
            scheduler: scheduler
        )

        service.captureCurrentTarget(excludingBundleIdentifier: "com.local.rainpaste")
        let result = service.pasteIntoCapturedTarget()

        XCTAssertTrue(result)
        XCTAssertEqual(targetApp.activationCount, 1)
        XCTAssertEqual(poster.postPasteCount, 1)
        XCTAssertEqual(scheduler.scheduledDelays, [0.08])
    }

    func testPasteReturnsFalseWhenAccessibilityNotGranted() {
        let targetApp = FakeRunningApplication(bundleIdentifier: "com.apple.TextEdit")
        let provider = FakeFrontmostApplicationProvider(frontmostApplication: targetApp)
        let poster = FakePasteEventPoster(isTrustedResult: false)
        let scheduler = ImmediateEventScheduler()
        let focusManager = NullFocusStateManager()
        let service = AutoPasteService(
            applicationProvider: provider,
            focusStateManager: focusManager,
            eventPoster: poster,
            scheduler: scheduler
        )

        service.captureCurrentTarget(excludingBundleIdentifier: "com.local.rainpaste")
        let result = service.pasteIntoCapturedTarget()

        XCTAssertFalse(result)
        XCTAssertEqual(targetApp.activationCount, 0)
        XCTAssertEqual(poster.postPasteCount, 0)
    }

    func testCaptureSkipsCurrentApp() {
        let currentApp = FakeRunningApplication(bundleIdentifier: "com.local.rainpaste")
        let provider = FakeFrontmostApplicationProvider(frontmostApplication: currentApp)
        let poster = FakePasteEventPoster(isTrustedResult: true)
        let scheduler = ImmediateEventScheduler()
        let focusManager = NullFocusStateManager()
        let service = AutoPasteService(
            applicationProvider: provider,
            focusStateManager: focusManager,
            eventPoster: poster,
            scheduler: scheduler
        )

        service.captureCurrentTarget(excludingBundleIdentifier: "com.local.rainpaste")
        let result = service.pasteIntoCapturedTarget()

        XCTAssertFalse(result)
        XCTAssertEqual(currentApp.activationCount, 0)
        XCTAssertEqual(poster.postPasteCount, 0)
    }

    func testCapturedTargetIsRetainedAcrossCaptureAndPaste() {
        let tracker = ActivationTracker()
        let provider = EphemeralFrontmostApplicationProvider(tracker: tracker)
        let poster = FakePasteEventPoster(isTrustedResult: true)
        let scheduler = ImmediateEventScheduler()
        let service = AutoPasteService(
            applicationProvider: provider,
            eventPoster: poster,
            scheduler: scheduler
        )

        service.captureCurrentTarget(excludingBundleIdentifier: "com.local.rainpaste")
        let result = service.pasteIntoCapturedTarget()

        XCTAssertTrue(result)
        XCTAssertEqual(tracker.activationCount, 1)
        XCTAssertEqual(poster.postPasteCount, 1)
    }

    func testPasteRestoresCapturedFocusBeforePostingPaste() {
        let targetApp = FakeRunningApplication(
            bundleIdentifier: "com.apple.TextEdit",
            processIdentifier: 42
        )
        let provider = FakeFrontmostApplicationProvider(frontmostApplication: targetApp)
        let eventLog = EventLog()
        let poster = FakePasteEventPoster(isTrustedResult: true, eventLog: eventLog)
        let scheduler = ImmediateEventScheduler()
        let focusManager = FakeFocusStateManager(eventLog: eventLog)
        let service = AutoPasteService(
            applicationProvider: provider,
            focusStateManager: focusManager,
            eventPoster: poster,
            scheduler: scheduler
        )

        service.captureCurrentTarget(excludingBundleIdentifier: "com.local.rainpaste")
        let result = service.pasteIntoCapturedTarget()

        XCTAssertTrue(result)
        XCTAssertEqual(focusManager.capturedProcessIdentifiers, [42])
        XCTAssertEqual(eventLog.events, ["restore", "paste"])
    }
}

private protocol TestRunningApplication: RunningApplicationActivating {}

private final class FakeRunningApplication: TestRunningApplication {
    let bundleIdentifier: String?
    let processIdentifier: pid_t
    private(set) var activationCount = 0

    init(bundleIdentifier: String?, processIdentifier: pid_t = 1) {
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
    }

    func activate(options: NSApplication.ActivationOptions) -> Bool {
        activationCount += 1
        return true
    }
}

private final class ActivationTracker {
    var activationCount = 0
}

private struct EphemeralFrontmostApplicationProvider: FrontmostApplicationProviding {
    let tracker: ActivationTracker

    func currentFrontmostApplication() -> RunningApplicationActivating? {
        FakeEphemeralRunningApplication(tracker: tracker)
    }
}

private final class FakeEphemeralRunningApplication: TestRunningApplication {
    let bundleIdentifier: String? = "com.apple.TextEdit"
    let processIdentifier: pid_t = 99
    private let tracker: ActivationTracker

    init(tracker: ActivationTracker) {
        self.tracker = tracker
    }

    func activate(options: NSApplication.ActivationOptions) -> Bool {
        tracker.activationCount += 1
        return true
    }
}

private struct FakeFrontmostApplicationProvider: FrontmostApplicationProviding {
    let frontmostApplication: RunningApplicationActivating?

    func currentFrontmostApplication() -> RunningApplicationActivating? {
        frontmostApplication
    }
}

private final class EventLog {
    var events: [String] = []
}

private final class FakePasteEventPoster: PasteEventPosting, @unchecked Sendable {
    let isTrustedResult: Bool
    private let eventLog: EventLog?
    private(set) var postPasteCount = 0

    init(isTrustedResult: Bool, eventLog: EventLog? = nil) {
        self.isTrustedResult = isTrustedResult
        self.eventLog = eventLog
    }

    func ensureTrusted(promptIfNeeded: Bool) -> Bool {
        isTrustedResult
    }

    func postPasteKeystroke() {
        postPasteCount += 1
        eventLog?.events.append("paste")
    }
}

private final class ImmediateEventScheduler: EventScheduling {
    private(set) var scheduledDelays: [TimeInterval] = []

    func schedule(after delay: TimeInterval, action: @escaping @Sendable () -> Void) {
        scheduledDelays.append(delay)
        action()
    }
}

private final class FakeFocusStateManager: FocusStateManaging, @unchecked Sendable {
    private let eventLog: EventLog
    private(set) var capturedProcessIdentifiers: [pid_t] = []

    init(eventLog: EventLog) {
        self.eventLog = eventLog
    }

    func captureFocusState(for processIdentifier: pid_t) -> FocusStateSnapshot? {
        capturedProcessIdentifiers.append(processIdentifier)
        return FocusStateSnapshot(processIdentifier: processIdentifier, focusedElement: "field-\(processIdentifier)" as CFTypeRef)
    }

    func restoreFocusState(_ snapshot: FocusStateSnapshot) -> Bool {
        eventLog.events.append("restore")
        return true
    }
}

private struct NullFocusStateManager: FocusStateManaging {
    func captureFocusState(for processIdentifier: pid_t) -> FocusStateSnapshot? {
        nil
    }

    func restoreFocusState(_ snapshot: FocusStateSnapshot) -> Bool {
        false
    }
}
