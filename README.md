# WristPane

Native, configurable Apple Watch dashboard with an iPhone companion, watch face complications, Smart Stack widgets, and Control Center controls. The app targets iOS 27 and watchOS 27.

## What is implemented

- iPhone configuration interface with six independently selectable dashboard slots.
- WatchConnectivity transfer of saved slot choices to the paired Apple Watch.
- Liquid Glass-styled native watchOS dashboard.
- Weather from Open-Meteo for the selected preset city and Watch battery display.
- Configurable WidgetKit watch face complications and Smart Stack widget.
- A watchOS Control Center button to open WristPane.
- Unsigned GitHub Actions compile checks and a Windows-sideload-friendly IPA containing the iPhone app, embedded Watch app, and Watch widget extension.

## What is **not** implemented yet

- Importing other apps' widgets or Live Activities. Apple doesn't expose that capability.
- Afterglow, Dewpoint, Exhale, or other third-party device integrations. Slots display a clearly labelled integration-needed state until real APIs are connected.
- A permanent replacement for Apple's watch face. Siri Modular remains Apple's native face.
- A pre-signed IPA. Apple Watch requires its own valid provisioning and signing; an iPhone-only FlareStore certificate isn't sufficient by itself.

## Building

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen). On a Mac with Xcode 27:

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project WristPane.xcodeproj -scheme WristPane -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project WristPane.xcodeproj -scheme WristPaneWatch -configuration Debug -destination 'generic/platform=watchOS' CODE_SIGNING_ALLOWED=NO build
```

The build workflow runs these validations on GitHub's Xcode 27 macOS runner. It publishes `WristPane-unsigned.ipa` with this exact nested structure:

```text
Payload/WristPane.app/
  PlugIns/WristPaneWatch.app/
    PlugIns/WristPaneWatchWidgets.appex/
```

The IPA and the extra app ZIP are **unsigned and not directly installable**. The IPA is intended for local Apple ID provisioning/signing experiments that support Watch companions. The GitHub Actions workflow checks the expected embedded paths before uploading. Version tags publish the IPA, ZIP and SHA-256 checksums to GitHub Releases.

Note the `PlugIns/WristPaneWatch.app` location: Xcode 26+ treats a single-target Watch app as a Foundation extension. The XcodeGen workaround in `project.yml` is required to avoid an Xcode validation failure that occurs when the old `Watch/` directory is used. An experimental Windows sideloader must also recognize this *modern* nesting; the older iLoader proof of concept did not specifically validate this topology.

## Free Apple ID installation from Windows (experimental)

**You do not have to pay for a developer membership just to test your own app.** Apple's free Xcode Personal Team offers device testing, but its provisioning profiles expire after 7 days. Xcode's official installation path requires a Mac. The Windows path below is experimental and is **not yet validated for iOS 27/watchOS 27 or this WristPane build**.

1. Run the **Build WristPane** workflow or open the latest successful GitHub Actions run. Download the artifact and extract `WristPane-unsigned.ipa`. **Do not submit it to FlareStore's normal iPhone-only signer**; the Watch app and widget need their own profiles.
2. On Windows, install Apple's device connectivity drivers (the iLoader documentation recommends installing [iTunes](https://apple.co/ms)). Connect your paired iPhone by cable, trust the computer, and ensure the Watch is nearby and paired. Enable Developer Mode on the devices if the installation requests it.
3. Open [WristPane's Build workflow](https://github.com/soum91/wristpane/actions/workflows/build.yml), click **Run workflow** on the `main` branch, and wait for the optional **Experimental Windows Watch installer** job. Download its `WristPane-Windows-Watch-Installer-<run number>` artifact and extract the Windows installer. This job is **manual-only** with **read-only repository permission**, and pins the previously validated [Rzbck/iloader](https://github.com/Rzbck/iloader/tree/feat/watch-companion-support-20260909) and [Rzbck/isideload](https://github.com/Rzbck/isideload/tree/feat/watch-companion-support-20260909) source revisions. It applies a small patch to recognize the newer `PlugIns/` Watch bundle layout. No signing accounts, credentials, or certificates are included or requested in GitHub Actions.
4. On your own Windows PC, run that experimental iLoader build, sign in with your own Apple Account **inside the app on your own computer**, select **Import IPA**, and select `WristPane-unsigned.ipa`. Let iLoader provision the paired Watch and separately sign the embedded watchOS bundles. Never share your password, pairing records, UDIDs, profiles, or certificates in GitHub issues or logs.
5. Verify the WristPane iPhone app opens. Then check the iPhone **Watch** app for the companion installation and attempt to open WristPane on the Watch. Add a complication and Smart Stack widget only after the Watch app launches.

The external project [documents a real Windows-driven iPhone + Watch installation](https://github.com/Rzbck/iloader-watch-companion) with these known-good revisions:

- iLoader: `70f37e9b4afc659ab44ec1944c034093f4cda416`
- isideload: `f7b9f3da570edd6824c29680545e710846d07df5`

The older [validated Windows build](https://github.com/Rzbck/iloader/actions/runs/34436587217/artifacts/10136476786) is also available for comparison but may not recognize WristPane's new Xcode 27 `PlugIns/` layout without our patch.

The physical result is evidence for that specific older test, **not proof WristPane installs on watchOS 27**. The patched Windows installer only receives CI build validation until someone tests a real Watch. If signing fails, record the first failing stage (profile creation, Watch signing, iPhone install, companion transfer, Watch install, or Watch launch), along with a **redacted** error message. Do not publish credentials or private provisioning data. If a free profile expires, re-sign/reinstall locally; GitHub Actions cannot install onto your physically paired Watch.

## User flow

1. On iPhone, choose six tile types and a weather city, then tap **Sync to Watch**.
2. Open the WristPane app on Apple Watch to view the dashboard.
3. Add WristPane complications from the built-in watch face editor, configuring each instance independently.
4. Add WristPane's widget to Smart Stack or its open-app button to Control Center.

Widgets and complications update according to watchOS budgets, so they are not guaranteed to refresh instantly.

## Privacy and signing

No Apple credentials, signing certificates, device UDIDs, or provisioning profiles belong in this repository. Do not upload any of them to GitHub artifacts or releases. Future signed distribution must be set up separately using encrypted repository secrets and appropriate watchOS provisioning.
