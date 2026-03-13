import AppKit
import ApplicationServices
import Carbon.HIToolbox

protocol RunningApplicationActivating: AnyObject {
    var bundleIdentifier: String? { get }
    var processIdentifier: pid_t { get }

    @discardableResult
    func activate(options: NSApplication.ActivationOptions) -> Bool
}

extension NSRunningApplication: RunningApplicationActivating {}

protocol FrontmostApplicationProviding {
    func currentFrontmostApplication() -> RunningApplicationActivating?
}

struct WorkspaceFrontmostApplicationProvider: FrontmostApplicationProviding {
    func currentFrontmostApplication() -> RunningApplicationActivating? {
        NSWorkspace.shared.frontmostApplication
    }
}

struct FocusStateSnapshot: @unchecked Sendable {
    let processIdentifier: pid_t
    let focusedElement: CFTypeRef
}

protocol FocusStateManaging: Sendable {
    func captureFocusState(for processIdentifier: pid_t) -> FocusStateSnapshot?
    func restoreFocusState(_ snapshot: FocusStateSnapshot) -> Bool
}

struct AccessibilityFocusStateManager: FocusStateManaging {
    func captureFocusState(for processIdentifier: pid_t) -> FocusStateSnapshot? {
        let applicationElement = AXUIElementCreateApplication(processIdentifier)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            applicationElement,
            kAXFocusedUIElementAttribute as CFString,
            &value
        )

        guard result == .success, let value else {
            return nil
        }

        return FocusStateSnapshot(
            processIdentifier: processIdentifier,
            focusedElement: value
        )
    }

    func restoreFocusState(_ snapshot: FocusStateSnapshot) -> Bool {
        let applicationElement = AXUIElementCreateApplication(snapshot.processIdentifier)
        let focusedElement = snapshot.focusedElement
        let appResult = AXUIElementSetAttributeValue(
            applicationElement,
            kAXFocusedUIElementAttribute as CFString,
            focusedElement
        )

        let elementResult = AXUIElementSetAttributeValue(
            focusedElement as! AXUIElement,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )

        return appResult == .success || elementResult == .success
    }
}

protocol PasteEventPosting: Sendable {
    func ensureTrusted(promptIfNeeded: Bool) -> Bool
    func postPasteKeystroke()
}

struct CGEventPastePoster: PasteEventPosting {
    func ensureTrusted(promptIfNeeded: Bool) -> Bool {
        if promptIfNeeded {
            let key = "AXTrustedCheckOptionPrompt"
            let options = [key: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    func postPasteKeystroke() {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: CGKeyCode(kVK_ANSI_V),
                  keyDown: true
              ),
              let keyUp = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: CGKeyCode(kVK_ANSI_V),
                  keyDown: false
              )
        else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

protocol EventScheduling {
    func schedule(after delay: TimeInterval, action: @escaping @Sendable () -> Void)
}

struct MainQueueEventScheduler: EventScheduling {
    func schedule(after delay: TimeInterval, action: @escaping @Sendable () -> Void) {
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            action()
        }
    }
}

@MainActor
final class AutoPasteService {
    private let applicationProvider: FrontmostApplicationProviding
    private let focusStateManager: FocusStateManaging
    private let eventPoster: PasteEventPosting
    private let scheduler: EventScheduling
    private var capturedTarget: RunningApplicationActivating?
    private var capturedFocusState: FocusStateSnapshot?

    init(
        applicationProvider: FrontmostApplicationProviding = WorkspaceFrontmostApplicationProvider(),
        focusStateManager: FocusStateManaging = AccessibilityFocusStateManager(),
        eventPoster: PasteEventPosting = CGEventPastePoster(),
        scheduler: EventScheduling = MainQueueEventScheduler()
    ) {
        self.applicationProvider = applicationProvider
        self.focusStateManager = focusStateManager
        self.eventPoster = eventPoster
        self.scheduler = scheduler
    }

    func captureCurrentTarget(excludingBundleIdentifier currentBundleIdentifier: String?) {
        guard let frontmostApplication = applicationProvider.currentFrontmostApplication() else {
            capturedTarget = nil
            capturedFocusState = nil
            return
        }

        if frontmostApplication.bundleIdentifier == currentBundleIdentifier {
            capturedTarget = nil
            capturedFocusState = nil
            return
        }

        capturedTarget = frontmostApplication
        capturedFocusState = focusStateManager.captureFocusState(
            for: frontmostApplication.processIdentifier
        )
    }

    @discardableResult
    func pasteIntoCapturedTarget(promptIfNeeded: Bool = true) -> Bool {
        guard let capturedTarget else {
            return false
        }

        guard eventPoster.ensureTrusted(promptIfNeeded: promptIfNeeded) else {
            return false
        }

        _ = capturedTarget.activate(options: [.activateAllWindows])
        let capturedFocusState = self.capturedFocusState
        let focusStateManager = self.focusStateManager
        scheduler.schedule(after: 0.08) { [eventPoster] in
            if let capturedFocusState {
                _ = focusStateManager.restoreFocusState(capturedFocusState)
            }
            eventPoster.postPasteKeystroke()
        }
        return true
    }
}
