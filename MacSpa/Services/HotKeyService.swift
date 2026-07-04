import AppKit
import Carbon.HIToolbox
import Observation

// MARK: - HotKey value

/// A key combo: a virtual key code plus a subset of NSEvent modifier flags.
struct HotKey: Equatable {
    var keyCode: UInt32
    var modifiers: UInt   // NSEvent.ModifierFlags rawValue (⌃⌥⇧⌘ subset)

    /// Human-readable combo, e.g. "⌃⌥⌘S".
    var display: String {
        let f = NSEvent.ModifierFlags(rawValue: modifiers)
        var s = ""
        if f.contains(.control) { s += "⌃" }
        if f.contains(.option)  { s += "⌥" }
        if f.contains(.shift)   { s += "⇧" }
        if f.contains(.command) { s += "⌘" }
        return s + KeyNames.name(Int(keyCode))
    }

    /// Individual key caps for chip-style display, e.g. ["⌃","⌥","⌘","S"].
    var keyCaps: [String] {
        let f = NSEvent.ModifierFlags(rawValue: modifiers)
        var caps: [String] = []
        if f.contains(.control) { caps.append("⌃") }
        if f.contains(.option)  { caps.append("⌥") }
        if f.contains(.shift)   { caps.append("⇧") }
        if f.contains(.command) { caps.append("⌘") }
        caps.append(KeyNames.name(Int(keyCode)))
        return caps
    }

    /// Carbon modifier mask for RegisterEventHotKey.
    var carbonModifiers: UInt32 {
        let f = NSEvent.ModifierFlags(rawValue: modifiers)
        var c: UInt32 = 0
        if f.contains(.command) { c |= UInt32(cmdKey) }
        if f.contains(.option)  { c |= UInt32(optionKey) }
        if f.contains(.control) { c |= UInt32(controlKey) }
        if f.contains(.shift)   { c |= UInt32(shiftKey) }
        return c
    }

    /// CoreGraphics flags for the session unlock check in EventTapService.
    var cgFlags: CGEventFlags {
        let f = NSEvent.ModifierFlags(rawValue: modifiers)
        var c: CGEventFlags = []
        if f.contains(.command) { c.insert(.maskCommand) }
        if f.contains(.option)  { c.insert(.maskAlternate) }
        if f.contains(.control) { c.insert(.maskControl) }
        if f.contains(.shift)   { c.insert(.maskShift) }
        return c
    }

    var encoded: String { "\(keyCode):\(modifiers)" }
    static func decode(_ s: String) -> HotKey? {
        let parts = s.split(separator: ":")
        guard parts.count == 2, let k = UInt32(parts[0]), let m = UInt(parts[1]) else { return nil }
        return HotKey(keyCode: k, modifiers: m)
    }
}

// MARK: - Which shortcut

enum ShortcutID: String, CaseIterable {
    case startSpa, unlock, openDashboard

    var storageKey: String { "shortcut.\(rawValue)" }
    var label: String {
        switch self {
        case .startSpa:      return "Start spa session"
        case .unlock:        return "Unlock during session"
        case .openDashboard: return "Open dashboard"
        }
    }
    /// Carbon hot-key id (0 = not a global hot key; unlock is handled by the event tap).
    var carbonID: UInt32 {
        switch self {
        case .startSpa: return 1
        case .openDashboard: return 2
        case .unlock: return 0
        }
    }
    var `default`: HotKey {
        let all: NSEvent.ModifierFlags = [.control, .option, .command]
        switch self {
        case .startSpa:      return HotKey(keyCode: 1,  modifiers: all.rawValue)                       // ⌃⌥⌘S
        case .unlock:        return HotKey(keyCode: 40, modifiers: all.rawValue)                       // ⌃⌥⌘K
        case .openDashboard: return HotKey(keyCode: 2,  modifiers: NSEvent.ModifierFlags.command.rawValue) // ⌘D
        }
    }
}

/// Reads/writes shortcuts in UserDefaults, falling back to defaults.
enum HotKeyStore {
    static func load(_ id: ShortcutID) -> HotKey {
        guard let s = UserDefaults.standard.string(forKey: id.storageKey),
              let hk = HotKey.decode(s) else { return id.default }
        return hk
    }
    static func save(_ id: ShortcutID, _ hk: HotKey) {
        UserDefaults.standard.set(hk.encoded, forKey: id.storageKey)
    }
}

// MARK: - Global hot-key registration (Carbon)

@Observable
@MainActor
final class HotKeyService {
    @ObservationIgnored var onStartSpa: (() -> Void)?
    @ObservationIgnored var onOpenDashboard: (() -> Void)?

    @ObservationIgnored private var installed = false
    @ObservationIgnored private var refs: [UInt32: EventHotKeyRef] = [:]

    /// Re-reads stored shortcuts and (re)registers the global hot keys.
    func reloadFromDefaults() {
        installHandlerIfNeeded()
        register(.startSpa)
        register(.openDashboard)
    }

    func handle(id: UInt32) {
        switch id {
        case ShortcutID.startSpa.carbonID:      onStartSpa?()
        case ShortcutID.openDashboard.carbonID: onOpenDashboard?()
        default: break
        }
    }

    private func installHandlerIfNeeded() {
        guard !installed else { return }
        installed = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), hotKeyEventHandler, 1, &spec,
                            Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    private func register(_ id: ShortcutID) {
        let carbonID = id.carbonID
        if let existing = refs[carbonID] {
            UnregisterEventHotKey(existing)
            refs[carbonID] = nil
        }
        let hk = HotKeyStore.load(id)
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: OSType(0x4D435350), id: carbonID) // 'MCSP'
        let status = RegisterEventHotKey(hk.keyCode, hk.carbonModifiers, hkID,
                                         GetApplicationEventTarget(), 0, &ref)
        if status == noErr { refs[carbonID] = ref }
    }
}

/// C callback - runs on the main run loop. Dispatches to the service instance.
private func hotKeyEventHandler(_ next: EventHandlerCallRef?, _ event: EventRef?,
                                _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event, let userData else { return noErr }
    var hkID = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject),
                      EventParamType(typeEventHotKeyID), nil,
                      MemoryLayout<EventHotKeyID>.size, nil, &hkID)
    let service = Unmanaged<HotKeyService>.fromOpaque(userData).takeUnretainedValue()
    let id = hkID.id
    MainActor.assumeIsolated { service.handle(id: id) }
    return noErr
}

// MARK: - Key code → display name (US layout, common keys)

enum KeyNames {
    static func name(_ code: Int) -> String { map[code] ?? "Key \(code)" }
    private static let map: [Int: String] = [
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H",
        34: "I", 38: "J", 40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P",
        12: "Q", 15: "R", 1: "S", 17: "T", 32: "U", 9: "V", 13: "W", 7: "X",
        16: "Y", 6: "Z",
        29: "0", 18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7",
        28: "8", 25: "9",
        49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 53: "Esc", 76: "Enter",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        55: "Cmd", 56: "Shift", 58: "Option", 59: "Control",
        27: "-", 24: "=", 33: "[", 30: "]", 41: ";", 39: "'",
        43: ",", 47: ".", 44: "/", 42: "\\", 50: "`"
    ]
}
