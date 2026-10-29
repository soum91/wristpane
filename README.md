# WristPane

Native, configurable Apple Watch dashboard with an iPhone companion, watch face complications, Smart Stack widgets, and Control Center controls. The app targets iOS 27 and watchOS 27.

## What is implemented

- iPhone configuration interface with six independently selectable dashboard slots.
- WatchConnectivity transfer of saved slot choices to the paired Apple Watch.
- Liquid Glass-styled native watchOS dashboard.
- Weather from Open-Meteo for the selected preset city and Watch battery display.
- Configurable WidgetKit watch face complications and Smart Stack widget.
- A watchOS Control Center button to open WristPane.
- Unsigned GitHub Actions compile checks and downloadable build archives.

## What is **not** implemented yet

- Importing other apps' widgets or Live Activities. Apple doesn't expose that capability.
- Afterglow, Dewpoint, Exhale, or other third-party device integrations. Slots display a clearly labelled integration-needed state until real APIs are connected.
- A permanent replacement for Apple's watch face. Siri Modular remains Apple's native face.
- A signed/installable IPA. Apple Watch requires its own valid provisioning and signing; an iPhone-only FlareStore certificate isn't sufficient by itself.

## Building

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen). On a Mac with Xcode 27:

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project WristPane.xcodeproj -scheme WristPane -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WristPane.xcodeproj -scheme WristPaneWatch -configuration Debug -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

The build workflow runs these validations on GitHub's Xcode 27 macOS runner. Its uploaded ZIP is **unsigned and not directly installable**; it is a compilation artifact for validation. Release tags also publish the ZIP and a SHA-256 checksum to GitHub Releases.

## User flow

1. On iPhone, choose six tile types and a weather city, then tap **Sync to Watch**.
2. Open the WristPane app on Apple Watch to view the dashboard.
3. Add WristPane complications from the built-in watch face editor, configuring each instance independently.
4. Add WristPane's widget to Smart Stack or its open-app button to Control Center.

Widgets and complications update according to watchOS budgets, so they are not guaranteed to refresh instantly.

## Privacy and signing

No Apple credentials, signing certificates, device UDIDs, or provisioning profiles belong in this repository. Do not upload any of them to GitHub artifacts or releases. Future signed distribution must be set up separately using encrypted repository secrets and appropriate watchOS provisioning.
