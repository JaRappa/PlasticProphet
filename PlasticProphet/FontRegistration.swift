import Foundation
import CoreText

/// Registers any .ttf or .otf files placed in the app bundle under a `Fonts/` subdirectory.
/// Drop your Montserrat .ttf/.otf files into `PlasticProphet/PlasticProphet/Fonts/` in the repo
/// and add them to your Xcode target (or ensure the folder is copied into the bundle) — they
/// will then be registered at app startup via `FontRegistration.registerFonts()`.
struct FontRegistration {
    static func registerFonts() {
        let exts = ["ttf", "otf"]
        for ext in exts {
            guard let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") else { continue }
            for url in urls {
                var error: Unmanaged<CFError>?
                let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
                if !success {
                    if let e = error?.takeRetainedValue() {
                        print("[FontRegistration] failed to register \(url.lastPathComponent): \(e)")
                    } else {
                        print("[FontRegistration] unknown error registering \(url.lastPathComponent)")
                    }
                } else {
                    print("[FontRegistration] registered \(url.lastPathComponent)")
                }
            }
        }
    }
}
