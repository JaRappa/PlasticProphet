How to add Montserrat fonts to this project

I added a runtime font registration helper (FontRegistration.swift) which will auto-register any .ttf/.otf files placed in the app bundle under `Fonts/` at app launch.

To add Montserrat to the project:

1. Download Montserrat font files (OTF/TTF) from a trusted source (e.g., Google Fonts) and place the files in this folder:
   PlasticProphet/PlasticProphet/Fonts/

   Recommended files (example names):
   - Montserrat-Regular.ttf
   - Montserrat-SemiBold.ttf
   - Montserrat-Bold.ttf

2. In Xcode, select each font file in the Project Navigator and ensure the file is included in the app target (check the "Target Membership").

3. (Optional) If you prefer Info.plist-based registration, add the filenames to the Info.plist key "Fonts provided by application" (UIAppFonts) — but this is not required because `FontRegistration.registerFonts()` will register fonts at runtime.

4. Build and run the app. The app will attempt to register fonts on startup and will print registration results to the console (use the Xcode debug console to confirm).

Notes:
- I cannot add Montserrat font binaries to the repo automatically because fonts are copyrighted and must be uploaded or downloaded explicitly by you.
- If you'd like, upload the Montserrat .ttf/.otf files here and I will add them into the `Fonts/` folder and confirm the app registers them.
