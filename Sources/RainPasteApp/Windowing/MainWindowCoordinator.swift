import AppKit
import SwiftUI

@MainActor
protocol CommandPanelWindowing: AnyObject {
    var keyCodeHandler: ((UInt16) -> Bool)? { get set }

    func showWithoutActivating()
    func closePanel()
}

@MainActor
final class MainWindowCoordinator {
    private let windowFactory: (AppViewModel) -> CommandPanelWindowing
    private var window: CommandPanelWindowing?

    init(
        windowFactory: @escaping (AppViewModel) -> CommandPanelWindowing = { viewModel in
            let hostingController = NSHostingController(rootView: MainWindowView(viewModel: viewModel))
            let window = CommandPanelWindow(contentViewController: hostingController)
            window.title = "RainPaste"
            window.setContentSize(NSSize(width: 860, height: 620))
            window.minSize = NSSize(width: 760, height: 520)
            window.center()
            window.isReleasedWhenClosed = false
            window.backgroundColor = .clear
            return window
        }
    ) {
        self.windowFactory = windowFactory
    }

    func show(viewModel: AppViewModel) {
        let window = makeWindowIfNeeded(viewModel: viewModel)
        window.keyCodeHandler = { keyCode in
            switch keyCode {
            case 53:
                viewModel.closePanel()
                return true
            case 125:
                viewModel.moveSelection(delta: 1)
                return true
            case 126:
                viewModel.moveSelection(delta: -1)
                return true
            case 36, 76:
                viewModel.activateSelectedItem()
                return true
            default:
                return false
            }
        }
        window.showWithoutActivating()
    }

    func close() {
        window?.closePanel()
    }

    private func makeWindowIfNeeded(viewModel: AppViewModel) -> CommandPanelWindowing {
        if let window {
            return window
        }

        let window = windowFactory(viewModel)
        self.window = window
        return window
    }
}

@MainActor
private final class CommandPanelWindow: NSPanel, CommandPanelWindowing {
    var keyCodeHandler: ((UInt16) -> Bool)?

    init(contentViewController: NSViewController) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 620),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.contentViewController = contentViewController
        isFloatingPanel = true
        level = .floating
        hasShadow = true
        isOpaque = false
        hidesOnDeactivate = false
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        animationBehavior = .utilityWindow
        isMovableByWindowBackground = true
    }

    func showWithoutActivating() {
        center()
        orderFrontRegardless()
        makeKey()
    }

    func closePanel() {
        orderOut(nil)
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, keyCodeHandler?(event.keyCode) == true {
            return
        }

        super.sendEvent(event)
    }
}
