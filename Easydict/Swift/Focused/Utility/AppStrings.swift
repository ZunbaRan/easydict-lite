// Copyright © 2026 Easydict contributors. GPL-3.0.

import Foundation

enum AppStrings {
    static var bundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle.main
        #endif
    }

    static func text(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }
}
