// EventTapService.swift
import CoreGraphics
@preconcurrency import AppKit
import Observation

/// Which input devices are locked during the current cleaning stage.
enum LockMode { case keyboard, trackpad, both
    var raw: Int { self == .keyboard ? 0 : (self == .trackpad ? 1 : 2) }
}

@Observable
@MainActor
final class EventTapService {
    var isBlocking = false
    var unlockKeyCode: CGKeyCode = 40  // K
    var unlockModifiers: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand]

    /// The device(s) to block right now. Changing it mid-session is honored live.
    var lockMode: LockMode = .keyboard { didSet { cachedLockMode = lockMode.raw } }

    // Snapshot copies readable from the nonisolated tap callback (Swift 6).
    @ObservationIgnored nonisolated(unsafe) private var cachedUnlockKeyCode: CGKeyCode = 40
    @ObservationIgnored nonisolated(unsafe) private var cachedUnlockModifiers: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand]
    @ObservationIgnored nonisolated(unsafe) private var cachedLockMode: Int = 0

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var selfRef: Unmanaged<EventTapService>?
    private var safetyTimer: Task<Void, Never>?
    var onUnlock: (() -> Void)?

    func startBlocking(timeoutSeconds: Int = 180) {
        guard !isBlocking else { return }
        guard AXIsProcessTrusted() else {
            requestAccessibility()
            return
        }
        cachedUnlockKeyCode = unlockKeyCode
        cachedUnlockModifiers = unlockModifiers
        cachedLockMode = lockMode.raw
        selfRef = Unmanaged.passRetained(self)

        // Tap keyboard AND pointer/trackpad events. The unlock combo is always
        // intercepted from the keyboard stream regardless of which device is locked.
        let keyboard: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        let mouseTypes: [CGEventType] = [
            .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged, .scrollWheel,
        ]
        var mask = keyboard
        for t in mouseTypes { mask |= (1 << t.rawValue) }

        let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let svc = Unmanaged<EventTapService>.fromOpaque(userInfo).takeUnretainedValue()
                return svc.handleEvent(type: type, event: event)
            },
            userInfo: selfRef!.toOpaque()
        )
        guard let tap else { selfRef?.release(); selfRef = nil; return }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isBlocking = true

        if timeoutSeconds > 0 {
            safetyTimer = Task {
                do { try await Task.sleep(for: .seconds(timeoutSeconds)) }
                catch { return }   // cancelled - do not unlock
                await MainActor.run { self.stopBlocking() }
            }
        }
    }

    func stopBlocking() {
        guard isBlocking else { return }
        safetyTimer?.cancel()
        safetyTimer = nil
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let src = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        selfRef?.release()
        selfRef = nil
        isBlocking = false
        onUnlock?()
    }

    // Called from the C callback - must not touch @MainActor state directly.
    nonisolated func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Unlock combo is always honored, even when the keyboard isn't the locked device.
        if type == .keyDown {
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags.intersection([.maskControl, .maskAlternate, .maskCommand, .maskShift])
            let required = cachedUnlockModifiers.intersection([.maskControl, .maskAlternate, .maskCommand, .maskShift])
            if keyCode == cachedUnlockKeyCode && !required.isEmpty && flags.isSuperset(of: required) {
                Task { @MainActor in self.stopBlocking() }
                return nil
            }
        }

        let isKeyboard = (type == .keyDown || type == .keyUp || type == .flagsChanged)
        let mode = cachedLockMode  // 0 keyboard, 1 trackpad, 2 both
        let block = isKeyboard ? (mode == 0 || mode == 2)
                               : (mode == 1 || mode == 2)
        return block ? nil : Unmanaged.passUnretained(event)
    }

    private func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
