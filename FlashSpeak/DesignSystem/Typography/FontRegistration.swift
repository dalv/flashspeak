import CoreText
import Foundation
import UIKit

/// Registers the bundled Noto Sans SC / JP / KR fonts with the process.
///
/// Runtime registration avoids an `UIAppFonts` Info.plist entry. Call
/// `registerBundledFonts()` once at launch; previews get it through
/// `DesignSystemPreview`. Repeated calls do nothing.
enum FontRegistration {
    static let postScriptNames = [
        "NotoSansSC-Regular", "NotoSansSC-Bold",
        "NotoSansJP-Regular", "NotoSansJP-Bold",
        "NotoSansKR-Regular", "NotoSansKR-Bold",
    ]

    static func registerBundledFonts() {
        _ = registration
    }

    private static let registration: Void = {
        let urls = postScriptNames.compactMap { name in
            Bundle.main.url(forResource: name, withExtension: "otf")
                ?? Bundle.main.url(forResource: name, withExtension: "otf", subdirectory: "Fonts")
        }
        assert(urls.count == postScriptNames.count, "Missing bundled Noto fonts")
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)

        #if DEBUG
            for name in postScriptNames {
                assert(UIFont(name: name, size: 17) != nil, "Font \(name) did not register")
            }
        #endif
    }()
}
