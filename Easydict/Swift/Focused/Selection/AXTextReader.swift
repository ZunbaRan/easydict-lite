// Copyright © 2026 Easydict contributors. GPL-3.0.

import AppKit
import ApplicationServices

/// Reads only the selection exposed by AX. It never invokes Copy, sends keys, or runs scripts.
enum AXTextReader {
    static func selectedText(processID: pid_t) -> String? {
        guard AXIsProcessTrusted() else { return nil }
        let app = AXUIElementCreateApplication(processID)
        AXUIElementSetMessagingTimeout(app, 0.25)
        guard let focused = attribute(app, name: kAXFocusedUIElementAttribute) else { return nil }
        guard CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
        let element = focused as! AXUIElement
        AXUIElementSetMessagingTimeout(element, 0.25)
        let role = attribute(element, name: kAXRoleAttribute) as? String
        let subrole = attribute(element, name: kAXSubroleAttribute) as? String
        guard role != kAXSecureTextFieldSubrole, subrole != kAXSecureTextFieldSubrole else { return nil }
        if let selected = attribute(element, name: kAXSelectedTextAttribute) as? String,
           !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return selected
        }
        guard let value = attribute(element, name: kAXValueAttribute) as? String,
              let rangeValue = attribute(element, name: kAXSelectedTextRangeAttribute),
              CFGetTypeID(rangeValue) == AXValueGetTypeID()
        else { return nil }
        let axRange = rangeValue as! AXValue
        guard AXValueGetType(axRange) == .cfRange else { return nil }
        var range = CFRange()
        guard AXValueGetValue(axRange, .cfRange, &range), range.location >= 0, range.length > 0,
              range.location <= (value as NSString).length,
              range.length <= (value as NSString).length - range.location
        else { return nil }
        return (value as NSString).substring(with: NSRange(location: range.location, length: range.length))
    }

    private static func attribute(_ element: AXUIElement, name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
}
