# ClipFox

Native macOS clipboard history app inspired by Maccy.

## Run

```bash
swift run ClipFox
```

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
