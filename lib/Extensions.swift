import Cocoa

let NAME_STRIP_REGEX = try! NSRegularExpression(pattern: #"(.+)\s+\(\s*\d+\s*\)\s*$"#)

func configure(_ action: (CGDisplayConfigRef) -> Bool) {
    var configRef: CGDisplayConfigRef?
    var err = CGBeginDisplayConfiguration(&configRef)
    guard err == .success, let config = configRef else {
        print("Error with CGBeginDisplayConfiguration: \(err)")
        return
    }

    guard action(config) else {
        _ = CGCancelDisplayConfiguration(config)
        return
    }

    err = CGCompleteDisplayConfiguration(config, .permanently)
    guard err == .success else {
        print("Error with CGCompleteDisplayConfiguration")
        _ = CGCancelDisplayConfiguration(config)
        return
    }
}

extension NSScreen {
    static var onlineDisplayIDs: [CGDirectDisplayID] {
        let maxDisplays: UInt32 = 16
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0

        let err = CGGetOnlineDisplayList(maxDisplays, &onlineDisplays, &displayCount)
        if err != .success {
            print("Error on getting online displays: \(err)")
        }

        return Array(onlineDisplays.prefix(Int(displayCount)))
    }

    var hasMouse: Bool {
        let mouseLocation = NSEvent.mouseLocation
        if NSMouseInRect(mouseLocation, frame, false) {
            return true
        }

        guard let event = CGEvent(source: nil) else {
            return false
        }

        let maxDisplays: UInt32 = 1
        var displaysWithCursor = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0

        let _ = CGGetDisplaysWithPoint(event.location, maxDisplays, &displaysWithCursor, &displayCount)
        guard let id = displaysWithCursor.first else {
            return false
        }
        return id == displayID
    }

    static var withMouse: NSScreen? {
        screens.first { $0.hasMouse }
    }

    var displayID: CGDirectDisplayID? {
        guard let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        else { return nil }
        return CGDirectDisplayID(id.uint32Value)
    }

    static func name(for id: CGDirectDisplayID) -> String? {
        screen(with: id)?.localizedName
    }

    static func screen(with id: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { $0.hasDisplayID(id) }
    }

    func hasDisplayID(_ id: CGDirectDisplayID) -> Bool {
        guard let screenNumber = displayID else { return false }
        return id == screenNumber
    }
}

extension MPDisplay {
    var name: String {
        isSidecarDisplay ? "Sidecar" : (titleName ?? displayName ?? "Unknown name")
    }
}

extension MPDisplayMgr {
    func matchDisplay(filter: String) -> MPDisplay? {
        guard let displays = displays as? [MPDisplay] else { return nil }

        if ["cursor", "current", "main"].contains(filter.lowercased()),
           let cursorDisplayID = NSScreen.withMouse?.displayID,
           let display = displays.first(where: { $0.displayID == cursorDisplayID })
        {
            return display
        }
        if let id = Int(filter), let display = displays.first(where: { $0.displayID == id }) {
            return display
        }
        if let uuid = UUID(uuidString: filter.uppercased()), let display = displays.first(where: { $0.uuid == uuid }) {
            return display
        }

        let filter = filter.lowercased()
        if filter == "sidecar" || filter == "ipad", let display = displays.first(where: \.isSidecarDisplay) {
            return display
        }
        if filter == "builtin" || filter == "built-in", let display = displays.first(where: \.isBuiltIn) {
            return display
        }
        if let display = displays.first(where: { $0.displayName?.lowercased() == filter }) {
            return display
        }

        return nil
    }

    func reconfigure(tries: Int = 10, _ action: (MPDisplayMgr) -> Void) {
        guard tryLock(tries: tries) else {
            return
        }

        notifyWillReconfigure()
        action(self)
        notifyReconfigure()
        unlockAccess()
    }

    func tryLock(tries: Int = 10) -> Bool {
        for i in 1 ... tries {
            if tryLockAccess() { return true }
            print("Failed to acquire display manager lock (try: \(i))")
            Thread.sleep(forTimeInterval: 0.05)
        }
        return false
    }
}

extension BinaryInteger {
    var s: String { String(self) }
}

extension Int32 {
    var cg: CGDirectDisplayID {
        CGDirectDisplayID(self)
    }
}
