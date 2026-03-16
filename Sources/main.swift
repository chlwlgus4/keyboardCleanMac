import AppKit
import ApplicationServices
import Carbon

private enum ScreenshotLanguage: String {
    case english = "en"
    case korean = "ko"

    static var current: ScreenshotLanguage? {
        let environment = ProcessInfo.processInfo.environment

        if let rawValue = environment["SCREENSHOT_UI_LANGUAGE"]?.lowercased() {
            if rawValue.hasPrefix("ko") {
                return .korean
            }

            if rawValue.hasPrefix("en") {
                return .english
            }
        }

        return nil
    }
}

private enum AppCopy {
    private static var screenshotLanguage: ScreenshotLanguage? {
        ScreenshotLanguage.current
    }

    private static func localized(english: String, korean: String) -> String {
        switch screenshotLanguage {
        case .korean:
            return korean
        case .english, nil:
            return english
        }
    }

    static var shortcutWindowTitle: String {
        localized(english: "Set Shortcut", korean: "단축키 설정")
    }

    static var shortcutHint: String {
        localized(english: "Press the shortcut you want", korean: "원하는 단축키를 누르세요")
    }

    static func currentShortcut(_ shortcut: Shortcut) -> String {
        localized(english: "Current: \(shortcut.displayString)", korean: "현재: \(shortcut.displayString)")
    }

    static var cancel: String {
        localized(english: "Cancel", korean: "취소")
    }

    static var controlWindowTitle: String {
        localized(english: "KeyboardClean Control", korean: "KeyboardClean 제어")
    }

    static func cleaningModeStatus(enabled: Bool) -> String {
        localized(
            english: enabled ? "Cleaning Mode: ON" : "Cleaning Mode: OFF",
            korean: enabled ? "클리닝 모드: 켜짐" : "클리닝 모드: 꺼짐"
        )
    }

    static func cleaningModeToggle(enabled: Bool) -> String {
        localized(
            english: enabled ? "Disable Cleaning Mode" : "Enable Cleaning Mode",
            korean: enabled ? "클리닝 모드 끄기" : "클리닝 모드 켜기"
        )
    }

    static var setShortcut: String {
        localized(english: "Set Shortcut...", korean: "단축키 설정...")
    }

    static var quit: String {
        localized(english: "Quit", korean: "종료")
    }

    static func hudCleaningMode(enabled: Bool) -> String {
        localized(
            english: enabled ? "Cleaning Mode ON" : "Cleaning Mode OFF",
            korean: enabled ? "클리닝 모드 켜짐" : "클리닝 모드 꺼짐"
        )
    }

    static var overlayTitle: String {
        localized(english: "Cleaning Mode ON", korean: "클리닝 모드 켜짐")
    }

    static func overlayShortcut(_ shortcut: Shortcut) -> String {
        localized(
            english: "Exit Shortcut: \(shortcut.displayString)",
            korean: "종료 단축키: \(shortcut.displayString)"
        )
    }

    static var overlayClose: String {
        localized(english: "Close", korean: "종료")
    }
}

private enum ShortcutStore {
    static let keyCode = "shortcut.keyCode"
    static let modifiers = "shortcut.modifiers"
    static let didShowFirstLaunchWindow = "ui.didShowFirstLaunchWindow"
}

fileprivate enum ScreenshotScene: String {
    case control
    case shortcut
    case cleaning
}

fileprivate enum LaunchMode {
    case standard
    case screenshot(ScreenshotScene)
    case exportScreenshot(ScreenshotScene, String)

    static func current() -> LaunchMode {
        let arguments = CommandLine.arguments

        func value(for option: String) -> String? {
            if let argument = arguments.first(where: { $0.hasPrefix("\(option)=") }) {
                return String(argument.split(separator: "=", maxSplits: 1).last ?? "")
            }

            if let index = arguments.firstIndex(of: option),
               arguments.indices.contains(index + 1) {
                return arguments[index + 1]
            }

            return nil
        }

        if let sceneRawValue = value(for: "--export-screenshot-scene"),
           let outputDirectory = value(for: "--output-dir"),
           let scene = ScreenshotScene(rawValue: sceneRawValue) {
            return .exportScreenshot(scene, outputDirectory)
        }

        if let sceneArgument = arguments.first(where: { $0.hasPrefix("--screenshot-scene=") }) {
            let rawValue = String(sceneArgument.split(separator: "=", maxSplits: 1).last ?? "")
            if let scene = ScreenshotScene(rawValue: rawValue) {
                return .screenshot(scene)
            }
        }

        if let index = arguments.firstIndex(of: "--screenshot-scene"),
           arguments.indices.contains(index + 1),
           let scene = ScreenshotScene(rawValue: arguments[index + 1]) {
            return .screenshot(scene)
        }

        return .standard
    }
}

struct Shortcut {
    let keyCode: UInt32
    let modifiers: UInt32

    static let `default` = Shortcut(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(cmdKey | shiftKey))

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Command") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("Control") }
        parts.append(keyName(for: keyCode))
        return parts.joined(separator: " + ")
    }

    static func load() -> Shortcut {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: ShortcutStore.keyCode) != nil,
              defaults.object(forKey: ShortcutStore.modifiers) != nil else {
            return .default
        }

        let keyCode = UInt32(defaults.integer(forKey: ShortcutStore.keyCode))
        let modifiers = UInt32(defaults.integer(forKey: ShortcutStore.modifiers))

        if modifiers == 0 {
            return .default
        }

        return Shortcut(keyCode: keyCode, modifiers: modifiers)
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(Int(keyCode), forKey: ShortcutStore.keyCode)
        defaults.set(Int(modifiers), forKey: ShortcutStore.modifiers)
    }
}

private func keyName(for keyCode: UInt32) -> String {
    switch keyCode {
    case UInt32(kVK_Return): return "Return"
    case UInt32(kVK_Escape): return "Escape"
    case UInt32(kVK_Delete): return "Delete"
    case UInt32(kVK_ForwardDelete): return "Forward Delete"
    case UInt32(kVK_Space): return "Space"
    case UInt32(kVK_LeftArrow): return "Left Arrow"
    case UInt32(kVK_RightArrow): return "Right Arrow"
    case UInt32(kVK_UpArrow): return "Up Arrow"
    case UInt32(kVK_DownArrow): return "Down Arrow"
    case UInt32(kVK_F1): return "F1"
    case UInt32(kVK_F2): return "F2"
    case UInt32(kVK_F3): return "F3"
    case UInt32(kVK_F4): return "F4"
    case UInt32(kVK_F5): return "F5"
    case UInt32(kVK_F6): return "F6"
    case UInt32(kVK_F7): return "F7"
    case UInt32(kVK_F8): return "F8"
    case UInt32(kVK_F9): return "F9"
    case UInt32(kVK_F10): return "F10"
    case UInt32(kVK_F11): return "F11"
    case UInt32(kVK_F12): return "F12"
    default:
        if let scalar = UnicodeScalar(Int(keyCodeToASCII(keyCode))) {
            return String(Character(scalar)).uppercased()
        }
        return "Key \(keyCode)"
    }
}

private func keyCodeToASCII(_ keyCode: UInt32) -> UInt8 {
    let map: [UInt32: UInt8] = [
        UInt32(kVK_ANSI_A): 65, UInt32(kVK_ANSI_B): 66, UInt32(kVK_ANSI_C): 67,
        UInt32(kVK_ANSI_D): 68, UInt32(kVK_ANSI_E): 69, UInt32(kVK_ANSI_F): 70,
        UInt32(kVK_ANSI_G): 71, UInt32(kVK_ANSI_H): 72, UInt32(kVK_ANSI_I): 73,
        UInt32(kVK_ANSI_J): 74, UInt32(kVK_ANSI_K): 75, UInt32(kVK_ANSI_L): 76,
        UInt32(kVK_ANSI_M): 77, UInt32(kVK_ANSI_N): 78, UInt32(kVK_ANSI_O): 79,
        UInt32(kVK_ANSI_P): 80, UInt32(kVK_ANSI_Q): 81, UInt32(kVK_ANSI_R): 82,
        UInt32(kVK_ANSI_S): 83, UInt32(kVK_ANSI_T): 84, UInt32(kVK_ANSI_U): 85,
        UInt32(kVK_ANSI_V): 86, UInt32(kVK_ANSI_W): 87, UInt32(kVK_ANSI_X): 88,
        UInt32(kVK_ANSI_Y): 89, UInt32(kVK_ANSI_Z): 90,
        UInt32(kVK_ANSI_0): 48, UInt32(kVK_ANSI_1): 49, UInt32(kVK_ANSI_2): 50,
        UInt32(kVK_ANSI_3): 51, UInt32(kVK_ANSI_4): 52, UInt32(kVK_ANSI_5): 53,
        UInt32(kVK_ANSI_6): 54, UInt32(kVK_ANSI_7): 55, UInt32(kVK_ANSI_8): 56,
        UInt32(kVK_ANSI_9): 57
    ]
    return map[keyCode] ?? 0
}

private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var result: UInt32 = 0
    if flags.contains(.command) { result |= UInt32(cmdKey) }
    if flags.contains(.shift) { result |= UInt32(shiftKey) }
    if flags.contains(.option) { result |= UInt32(optionKey) }
    if flags.contains(.control) { result |= UInt32(controlKey) }
    return result
}

final class KeyboardBlocker {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var toggleShortcut = Shortcut.default
    var cleaningModeEnabled = false

    func setToggleShortcut(_ shortcut: Shortcut) {
        toggleShortcut = shortcut
    }

    func start() -> Bool {
        if eventTap != nil {
            return true
        }

        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passRetained(event)
            }

            let blocker = Unmanaged<KeyboardBlocker>.fromOpaque(userInfo).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = blocker.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passRetained(event)
            }

            if blocker.cleaningModeEnabled {
                if type == .flagsChanged {
                    // Keep modifier state in sync so the global shortcut can still be recognized.
                    return Unmanaged.passRetained(event)
                }

                if type == .keyDown || type == .keyUp {
                    if blocker.isToggleShortcutEvent(event) {
                        return Unmanaged.passRetained(event)
                    }
                    return nil
                }
            }

            return Unmanaged.passRetained(event)
        }

        let userInfo = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: userInfo
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }

        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
        cleaningModeEnabled = false
    }

    private func isToggleShortcutEvent(_ event: CGEvent) -> Bool {
        let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
        guard keyCode == toggleShortcut.keyCode else {
            return false
        }

        let flags = event.flags
        var activeModifiers: UInt32 = 0
        if flags.contains(.maskCommand) { activeModifiers |= UInt32(cmdKey) }
        if flags.contains(.maskShift) { activeModifiers |= UInt32(shiftKey) }
        if flags.contains(.maskAlternate) { activeModifiers |= UInt32(optionKey) }
        if flags.contains(.maskControl) { activeModifiers |= UInt32(controlKey) }

        let userMask = UInt32(cmdKey | shiftKey | optionKey | controlKey)
        return (activeModifiers & userMask) == (toggleShortcut.modifiers & userMask)
    }
}

final class GlobalHotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let callback: () -> Void

    init?(callback: @escaping () -> Void) {
        self.callback = callback

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if result == noErr,
                   hotKeyID.signature == OSType(0x4B434C4E),
                   hotKeyID.id == 1 {
                    manager.callback()
                    return noErr
                }

                return OSStatus(eventNotHandledErr)
            },
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )

        guard status == noErr else {
            return nil
        }
    }

    func register(keyCode: UInt32, modifiers: UInt32) -> Bool {
        unregister()

        let hotKeyID = EventHotKeyID(signature: OSType(0x4B434C4E), id: 1) // "KCLN"
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        return status == noErr
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    deinit {
        unregister()
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
}

final class ShortcutCaptureView: NSView {
    var onCapture: ((Shortcut) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        let modifiers = carbonModifiers(from: flags)
        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        let keyCode = UInt32(event.keyCode)
        let shortcut = Shortcut(keyCode: keyCode, modifiers: modifiers)
        onCapture?(shortcut)
    }
}

final class ShortcutWindowController: NSWindowController {
    private let hintLabel = NSTextField(labelWithString: AppCopy.shortcutHint)
    private let currentLabel: NSTextField
    private let captureView = ShortcutCaptureView(frame: .zero)
    private let onCapture: (Shortcut) -> Void

    init(currentShortcut: Shortcut, onCapture: @escaping (Shortcut) -> Void) {
        self.currentLabel = NSTextField(labelWithString: AppCopy.currentShortcut(currentShortcut))
        self.onCapture = onCapture

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 170),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppCopy.shortcutWindowTitle
        window.center()

        super.init(window: window)
        setupUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        hintLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        hintLabel.alignment = .center
        currentLabel.alignment = .center

        captureView.wantsLayer = true
        captureView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        captureView.layer?.cornerRadius = 8
        captureView.translatesAutoresizingMaskIntoConstraints = false
        captureView.onCapture = { [weak self] shortcut in
            self?.onCapture(shortcut)
            self?.close()
        }

        let infoStack = NSStackView(views: [hintLabel, currentLabel])
        infoStack.orientation = .vertical
        infoStack.alignment = .centerX
        infoStack.spacing = 12
        infoStack.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = NSButton(title: AppCopy.cancel, target: self, action: #selector(cancelPressed))
        cancelButton.bezelStyle = .rounded
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(captureView)
        contentView.addSubview(infoStack)
        contentView.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            infoStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            infoStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),
            cancelButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            captureView.topAnchor.constraint(equalTo: contentView.topAnchor),
            captureView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            captureView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            captureView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    @objc private func cancelPressed() {
        close()
    }
}

final class FallbackControlWindowController: NSWindowController {
    private let statusLabel = NSTextField(labelWithString: AppCopy.cleaningModeStatus(enabled: false))
    private let toggleButton = NSButton(title: AppCopy.cleaningModeToggle(enabled: false), target: nil, action: nil)
    private let shortcutButton = NSButton(title: AppCopy.setShortcut, target: nil, action: nil)
    private let quitButton = NSButton(title: AppCopy.quit, target: nil, action: nil)

    init(onToggle: Selector, onSetShortcut: Selector, onQuit: Selector, target: AnyObject) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppCopy.controlWindowTitle
        window.center()

        super.init(window: window)

        guard let contentView = window.contentView else { return }

        statusLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        statusLabel.alignment = .center

        [toggleButton, shortcutButton, quitButton].forEach {
            $0.bezelStyle = .rounded
            $0.controlSize = .regular
            $0.target = target
        }
        toggleButton.action = onToggle
        shortcutButton.action = onSetShortcut
        quitButton.action = onQuit

        let stack = NSStackView(views: [statusLabel, toggleButton, shortcutButton, quitButton])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { nil }

    func setCleaningMode(_ enabled: Bool) {
        statusLabel.stringValue = AppCopy.cleaningModeStatus(enabled: enabled)
        toggleButton.title = AppCopy.cleaningModeToggle(enabled: enabled)
    }
}

final class ModeHUDController {
    private let panel: NSPanel
    private let label = NSTextField(labelWithString: "")
    private var hideWorkItem: DispatchWorkItem?

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 72),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hasShadow = true
        panel.backgroundColor = NSColor(calibratedWhite: 0.10, alpha: 0.92)
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true

        guard let contentView = panel.contentView else { return }
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func show(isEnabled: Bool) {
        hideWorkItem?.cancel()
        label.stringValue = AppCopy.hudCleaningMode(enabled: isEnabled)

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = panel.frame.size
            let origin = NSPoint(
                x: frame.midX - size.width / 2,
                y: frame.maxY - size.height - 40
            )
            panel.setFrameOrigin(origin)
        }

        panel.orderFrontRegardless()

        let workItem = DispatchWorkItem { [weak self] in
            self?.panel.orderOut(nil)
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
}

final class CleaningOverlayController {
    private let panel: NSPanel
    private let titleLabel = NSTextField(labelWithString: AppCopy.overlayTitle)
    private let shortcutLabel = NSTextField(labelWithString: "")
    private let closeButton = NSButton(title: AppCopy.overlayClose, target: nil, action: nil)
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 128),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.hasShadow = true
        panel.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 0.95)
        panel.isOpaque = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false

        setupUI()
    }

    private func setupUI() {
        guard let contentView = panel.contentView else { return }

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center

        shortcutLabel.font = .systemFont(ofSize: 13, weight: .medium)
        shortcutLabel.textColor = .white
        shortcutLabel.alignment = .center

        closeButton.bezelStyle = .rounded
        closeButton.target = self
        closeButton.action = #selector(closePressed)

        let stack = NSStackView(views: [titleLabel, shortcutLabel, closeButton])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func show(shortcut: Shortcut) {
        updateShortcut(shortcut)
        positionPanelAtTopRight()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func updateShortcut(_ shortcut: Shortcut) {
        shortcutLabel.stringValue = AppCopy.overlayShortcut(shortcut)
    }

    var window: NSWindow { panel }

    private func positionPanelAtTopRight() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }

        let panelSize = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.maxX - panelSize.width - 20,
            y: visibleFrame.maxY - panelSize.height - 20
        )
        panel.setFrameOrigin(origin)
    }

    @objc private func closePressed() {
        onClose()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let launchMode: LaunchMode
    private let blocker = KeyboardBlocker()
    private let hudController = ModeHUDController()
    private lazy var cleaningOverlayController = CleaningOverlayController(onClose: { [weak self] in
        self?.disableCleaningModeFromOverlay()
    })
    private var statusItem: NSStatusItem!
    private var toggleItem: NSMenuItem!
    private var shortcutInfoItem: NSMenuItem!
    private var hotKeyManager: GlobalHotKeyManager?
    private var shortcutWindowController: ShortcutWindowController?
    private var fallbackWindowController: FallbackControlWindowController?
    private var statusItemHealthTimer: Timer?
    private var currentShortcut = Shortcut.default
    private var cachedAppIcon: NSImage?

    fileprivate init(launchMode: LaunchMode) {
        self.launchMode = launchMode
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        currentShortcut = Shortcut.load()

        switch launchMode {
        case let .screenshot(scene):
            NSApp.setActivationPolicy(.regular)
            showScreenshotScene(scene)
            return
        case let .exportScreenshot(scene, outputDirectory):
            NSApp.setActivationPolicy(.regular)
            showScreenshotScene(scene)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.exportScreenshotScene(scene, outputDirectory: outputDirectory)
            }
            return
        case .standard:
            break
        }

        NSApp.setActivationPolicy(.accessory)
        installOrRepairStatusItem()

        let defaults = UserDefaults.standard
        let firstLaunchWindowNotShown = !defaults.bool(forKey: ShortcutStore.didShowFirstLaunchWindow)
        if firstLaunchWindowNotShown || statusItem.button == nil {
            showControlWindow()
            defaults.set(true, forKey: ShortcutStore.didShowFirstLaunchWindow)
        }

        statusItemHealthTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.installOrRepairStatusItem()
        }

        hotKeyManager = GlobalHotKeyManager(callback: { [weak self] in
            self?.toggleCleaningMode(showPermissionAlert: true)
        })

        applyShortcut(currentShortcut, save: false)
    }

    private func showScreenshotScene(_ scene: ScreenshotScene) {
        switch scene {
        case .control:
            showControlWindow()
            fallbackWindowController?.setCleaningMode(false)
            positionWindow(fallbackWindowController?.window, xFraction: 0.68, yFraction: 0.52)
        case .shortcut:
            let controller = ShortcutWindowController(currentShortcut: currentShortcut) { _ in }
            shortcutWindowController = controller
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            positionWindow(controller.window, xFraction: 0.68, yFraction: 0.54)
        case .cleaning:
            showControlWindow()
            fallbackWindowController?.setCleaningMode(true)
            positionWindow(fallbackWindowController?.window, xFraction: 0.30, yFraction: 0.48)
            cleaningOverlayController.show(shortcut: currentShortcut)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func exportScreenshotScene(_ scene: ScreenshotScene, outputDirectory: String) {
        let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            switch scene {
            case .control:
                try export(window: fallbackWindowController?.window, named: "control", to: directoryURL)
            case .shortcut:
                try export(window: shortcutWindowController?.window, named: "shortcut", to: directoryURL)
            case .cleaning:
                try export(window: fallbackWindowController?.window, named: "cleaning-primary", to: directoryURL)
                try export(window: cleaningOverlayController.window, named: "cleaning-overlay", to: directoryURL)
            }
        } catch {
            fputs("Failed to export screenshot scene: \(error)\n", stderr)
        }

        NSApp.terminate(nil)
    }

    private func export(window: NSWindow?, named fileName: String, to directoryURL: URL) throws {
        guard let window else {
            throw NSError(domain: "KeyboardClean", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing window for screenshot export."])
        }

        window.displayIfNeeded()

        guard let renderView = window.contentView?.superview ?? window.contentView else {
            throw NSError(domain: "KeyboardClean", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to access window content for export."])
        }

        let bounds = renderView.bounds
        let scale = Int(window.backingScaleFactor)
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: max(Int(bounds.width) * max(scale, 1), 1),
            pixelsHigh: max(Int(bounds.height) * max(scale, 1), 1),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw NSError(domain: "KeyboardClean", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to create bitmap representation."])
        }

        representation.size = bounds.size
        renderView.cacheDisplay(in: bounds, to: representation)

        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "KeyboardClean", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG data."])
        }

        try data.write(to: directoryURL.appendingPathComponent("\(fileName).png"))
    }

    private func positionWindow(_ window: NSWindow?, xFraction: CGFloat, yFraction: CGFloat) {
        guard let window,
              let visibleFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else {
            return
        }

        let size = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.minX + (visibleFrame.width * xFraction) - (size.width / 2),
            y: visibleFrame.minY + (visibleFrame.height * yFraction) - (size.height / 2)
        )
        window.setFrameOrigin(origin)
    }

    private func installOrRepairStatusItem() {
        if statusItem == nil || statusItem.button == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem.isVisible = true
            statusItem.menu = buildStatusMenu()
        }
        statusItem.isVisible = true
        applyStatusBarIcon(isLocked: blocker.cleaningModeEnabled)
    }

    private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()

        toggleItem = NSMenuItem(
            title: blocker.cleaningModeEnabled ? "Disable Cleaning Mode" : "Enable Cleaning Mode",
            action: #selector(toggleCleaningModeFromMenu),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        shortcutInfoItem = NSMenuItem(title: "Shortcut: \(currentShortcut.displayString)", action: nil, keyEquivalent: "")
        shortcutInfoItem.isEnabled = false
        menu.addItem(shortcutInfoItem)

        let setShortcutItem = NSMenuItem(title: "Set Shortcut...", action: #selector(openShortcutSetter), keyEquivalent: "")
        setShortcutItem.target = self
        menu.addItem(setShortcutItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func showControlWindow() {
        if fallbackWindowController == nil {
            let controller = FallbackControlWindowController(
                onToggle: #selector(toggleCleaningModeFromMenu),
                onSetShortcut: #selector(openShortcutSetter),
                onQuit: #selector(quitApp),
                target: self
            )
            fallbackWindowController = controller
        }

        fallbackWindowController?.showWindow(nil)
        fallbackWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openShortcutSetter() {
        NSApp.activate(ignoringOtherApps: true)

        let controller = ShortcutWindowController(currentShortcut: currentShortcut) { [weak self] shortcut in
            self?.applyShortcut(shortcut, save: true)
        }

        shortcutWindowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private func applyShortcut(_ shortcut: Shortcut, save: Bool) {
        guard let manager = hotKeyManager else { return }

        if manager.register(keyCode: shortcut.keyCode, modifiers: shortcut.modifiers) {
            currentShortcut = shortcut
            blocker.setToggleShortcut(shortcut)
            shortcutInfoItem.title = "Shortcut: \(shortcut.displayString)"
            cleaningOverlayController.updateShortcut(shortcut)
            if save {
                shortcut.save()
            }
            return
        }

        showShortcutRegisterFailureAlert()

        if !manager.register(keyCode: currentShortcut.keyCode, modifiers: currentShortcut.modifiers) {
            _ = manager.register(keyCode: Shortcut.default.keyCode, modifiers: Shortcut.default.modifiers)
            currentShortcut = .default
            blocker.setToggleShortcut(.default)
            shortcutInfoItem.title = "Shortcut: \(currentShortcut.displayString)"
        }
    }

    @objc private func toggleCleaningModeFromMenu() {
        toggleCleaningMode(showPermissionAlert: true)
    }

    @objc private func disableCleaningModeFromOverlay() {
        guard blocker.cleaningModeEnabled else { return }
        blocker.cleaningModeEnabled = false
        toggleItem.title = "Enable Cleaning Mode"
        applyStatusBarIcon(isLocked: false)
        fallbackWindowController?.setCleaningMode(false)
        cleaningOverlayController.hide()
        hudController.show(isEnabled: false)
    }

    private func toggleCleaningMode(showPermissionAlert: Bool) {
        if blocker.cleaningModeEnabled {
            disableCleaningModeFromOverlay()
            return
        }

        if !AXIsProcessTrusted() {
            if showPermissionAlert {
                showPermissionAlertDialog()
            }
            return
        }

        guard blocker.start() else {
            showTapFailureAlert()
            return
        }

        blocker.cleaningModeEnabled = true
        toggleItem.title = "Disable Cleaning Mode"
        applyStatusBarIcon(isLocked: true)
        fallbackWindowController?.setCleaningMode(true)
        cleaningOverlayController.show(shortcut: currentShortcut)
        hudController.show(isEnabled: true)
    }

    @objc private func quitApp() {
        statusItemHealthTimer?.invalidate()
        cleaningOverlayController.hide()
        blocker.stop()
        NSApp.terminate(nil)
    }

    private func showPermissionAlertDialog() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Needed"
        alert.informativeText = "키 입력 차단을 위해 손쉬운 사용(Accessibility) 권한이 필요합니다.\n시스템 설정에서 이 앱을 허용한 뒤, 앱을 완전히 종료 후 다시 실행하세요."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showTapFailureAlert() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Failed to Enable Cleaning Mode"
        alert.informativeText = "이 앱이 키 이벤트 탭을 만들 수 없습니다. 권한을 확인하고 다시 실행해 주세요."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showShortcutRegisterFailureAlert() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Shortcut Registration Failed"
        alert.informativeText = "해당 단축키를 등록할 수 없습니다. 다른 조합을 선택해 주세요."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func applyStatusBarIcon(isLocked: Bool) {
        guard let button = statusItem.button else { return }
        if let icon = statusBarSymbolImage(isLocked: isLocked) {
            button.image = icon
            button.title = ""
            return
        }

        if let appIcon = statusBarAppIcon() {
            button.image = appIcon
            button.title = ""
            return
        }

        button.image = nil
        button.title = isLocked ? "L" : "K"
    }

    private func statusBarSymbolImage(isLocked: Bool) -> NSImage? {
        guard #available(macOS 11.0, *) else { return nil }

        let symbolNames = isLocked
            ? ["lock.keyboard", "keyboard.badge.ellipsis", "lock.fill", "lock"]
            : ["keyboard", "keyboard.fill"]

        for name in symbolNames {
            if let symbol = NSImage(systemSymbolName: name, accessibilityDescription: "KeyboardClean") {
                symbol.isTemplate = true
                return symbol
            }
        }
        return nil
    }

    private func statusBarAppIcon() -> NSImage? {
        if let cached = cachedAppIcon {
            return cached
        }

        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else {
            return nil
        }

        icon.size = NSSize(width: 18, height: 18)
        cachedAppIcon = icon
        return icon
    }
}

let app = NSApplication.shared
let delegate = AppDelegate(launchMode: LaunchMode.current())
app.delegate = delegate
app.run()
