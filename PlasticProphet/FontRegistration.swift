import Foundation
import CoreText

/// Registers any .ttf or .otf files placed in the app bundle under a `Fonts/` subdirectory.
/// Drop your Montserrat .ttf/.otf files into `PlasticProphet/PlasticProphet/Fonts/` in the repo
/// and add them to your Xcode target (or ensure the folder is copied into the bundle) — they
/// will then be registered at app startup via `FontRegistration.registerFonts()`.
struct FontRegistration {
    static func registerFonts() {
        let exts = ["ttf", "otf"]
        // Collect URLs from both a "Fonts" subdirectory and the bundle root to be more
        // forgiving about how developers add files in Xcode (group vs folder reference).
        var urlsSet = Set<URL>()

        for ext in exts {
            if let subdirURLs = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") {
                urlsSet.formUnion(subdirURLs)
            }
            if let rootURLs = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                // Avoid adding duplicates that are already inside a Fonts/ subdirectory
                for u in rootURLs where !u.path.contains("/Fonts/") {
                    urlsSet.insert(u)
                }
            }
        }

        if urlsSet.isEmpty {
            print("[FontRegistration] no font files found in bundle (checked Fonts/ and bundle root)")
        }

        for url in urlsSet.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
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
