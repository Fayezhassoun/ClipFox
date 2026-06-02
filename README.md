# ClipFox

Native macOS clipboard history app inspired by Maccy.

## Run from source

```bash
swift run ClipFox
```

## Build an installable .app and DMG

```bash
Scripts/build-app.sh   # → build/ClipFox.app  (ad-hoc signed)
Scripts/make-dmg.sh    # → build/ClipFox-0.1.0.dmg
```

The DMG is unsigned by Apple, so the first launch on another Mac
needs **right-click → Open → Open** to bypass Gatekeeper. After
that, macOS will prompt for **Accessibility** permission (needed
for paste-on-select) in System Settings → Privacy & Security.

## Verify

```bash
swift run ClipFoxCoreCheck
swift build
```

## iCloud Sync

ClipFox uses CloudKit private database sync with this container:

```text
iCloud.com.fayez.clipfox
```

macOS apps do not show a separate iCloud login inside the app. The user signs in through System Settings, then the app checks account status and syncs through CloudKit.

For real multi-device sync, create an Xcode app target or signed app bundle with the CloudKit capability and the entitlements in:

```text
Config/ClipFox-iCloud.entitlements
```

The SwiftPM debug executable can build and launch, but CloudKit writes require a properly signed app with an iCloud container enabled in the Apple Developer account.
