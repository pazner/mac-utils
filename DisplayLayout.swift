import Cocoa
import ColorSync
import Foundation

func rotate(display: MPDisplay, orientation: Int32) {
    let id = display.displayID
    let name = display.name

    guard display.canChangeOrientation() else {
        print("\nThe display does not support changing orientation: \(name) [ID: \(id)]")
        return
    }

    print("\nChanging orientation for \(name) [ID: \(id)]: \(display.orientation) -> \(orientation)")
    display.orientation = orientation
}

func setOrigin(display: MPDisplay, x: Int32, y: Int32) {
    configure { config in
        CGConfigureDisplayOrigin(config, UInt32(display.displayID), x, y)
        return true
    }
}

func printDisplays(_ displays: [MPDisplay]) {
    print("ID\tUUID                             \tCan Change Orientation\tOrientation\tName")
    for panel in displays {
        print(
            "\(panel.displayID)\t\(panel.uuid?.uuidString ?? "")\t\(panel.canChangeOrientation())                \t\(panel.orientation)°        \t\(panel.name)"
        )
    }
}

func main() {
    guard let mgr = MPDisplayMgr(), let displays = mgr.displays as? [MPDisplay] else { return }
    printDisplays(displays)

    guard CommandLine.arguments.count >= 5, let orientation = Int32(CommandLine.arguments[2]),
          [0, 90, 180, 270].contains(orientation), let x = Int32(CommandLine.arguments[3]), let y = Int32(CommandLine.arguments[4])
    else {
        print("\nUsage: \(CommandLine.arguments[0]) <id-uuid-or-name> <portrait | landscape> x y")
        return
    }

    let arg = CommandLine.arguments[1]

    guard let display = mgr.matchDisplay(filter: arg) else {
        print("\nNo display found for query: \(arg)")
        return
    }

    rotate(display: display, orientation: orientation)
    setOrigin(display: display, x: x, y: y)
}

main()
