# Building and running this fork

This is a fork of the open-source eqMac (v1.3.2). It builds on current macOS and Xcode, and
it installs **next to** the official eqMac without touching it:

| | Official eqMac | This fork |
|---|---|---|
| App bundle ID (settings, presets) | `com.bitgapp.eqmac` | `com.scaeve.eqmac` |
| Audio driver | `/Library/Audio/Plug-Ins/HAL/eqMac.driver` | `/Library/Audio/Plug-Ins/HAL/eqMacFork.driver` |
| Updates | Sparkle, from eqmac.app | none; *Releases on GitHub* opens this repo |
| UI | downloaded from the developer's server | bundled in the app |
| Crash reports / analytics | Sentry / Google Analytics, opt-in | removed |

Don't run both apps at the same time: each one tries to make its own driver the system output.

## Requirements

- macOS 12 or newer (tested on macOS 27)
- Xcode (tested with Xcode 27)
- [CocoaPods](https://cocoapods.org): `brew install cocoapods`
- Node.js 16 or newer (tested with 16 and 25). `ui/scripts/ng.js` handles the OpenSSL
  flag the old Angular 12 toolchain needs on Node 17+.

## Build

```sh
native/scripts/build.sh            # Release (default)
native/scripts/build.sh Debug
```

This installs JS dependencies (first run only), builds the web UI, runs `pod install`, and
builds the driver and the app. Results:

```
native/build/Build/Products/<Configuration>/eqMac.app
native/build/Build/Products/<Configuration>/eqMacFork.driver
```

Build logs are in `native/build/script-logs/`.

## Install the audio driver

eqMac captures system audio through a virtual audio device provided by its driver. Install it
once, and again whenever the driver code changes:

```sh
native/scripts/install-driver.sh            # or: install-driver.sh Debug
```

It asks for your admin password, copies `eqMacFork.driver` into `/Library/Audio/Plug-Ins/HAL/`
and restarts Core Audio (sound drops out for a second). It never touches the official
`eqMac.driver`.

## Run

```sh
open native/build/Build/Products/Release/eqMac.app
```

You can also copy the app somewhere permanent, e.g. `/Applications/eqMac Fork.app`, so it
doesn't overwrite the official `/Applications/eqMac.app`.

On first start macOS asks for **microphone** access. eqMac needs it to read the audio coming
through its driver; nothing is recorded. Local builds are signed ad hoc, so macOS may ask
again after you rebuild the app. Signing with your own Apple Development certificate (free
with an Apple ID) avoids that: set `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY` for the
`eqMac` target in Xcode.

## Developing

- Open `native/eqMac.xcworkspace` in Xcode (not the `.xcodeproj`).
- The UI is Angular 12 in `ui/` (shared components in `modules/components`). For live UI
  work, run `cd ui && npm start` and launch a **Debug** build: Debug builds load the UI from
  `http://localhost:8080` when that dev server is running, otherwise the bundled UI.
- Release builds always use the UI bundled into the app by `npm run build`.
- The Swift app and the UI talk over a JS bridge; routes are defined in the `*DataBus.swift`
  files and called from the `*.service.ts` files.
- `native/vendor/AMCoreAudio` is a vendored dependency; see its README for why.

## Uninstall

```sh
native/scripts/uninstall-driver.sh
rm -rf "/Applications/eqMac Fork.app"      # wherever you put the app
defaults delete com.scaeve.eqmac
rm -rf ~/Library/Application\ Support/com.scaeve.eqmac
```

The official eqMac and its driver are not affected. If you used *Launch on Startup*, turn it
off in eqMac's settings before deleting the app.

## Troubleshooting

- **"The eqMac audio driver is not installed"**: run `native/scripts/install-driver.sh`, then
  start eqMac again. If it still appears, check that
  `/Library/Audio/Plug-Ins/HAL/eqMacFork.driver` exists and restart the Mac.
- **No sound**: eqMac must be running for audio routed through its driver to reach your
  speakers. Quit the official eqMac if it's running.
- **Build fails in `pod install`**: run `pod repo update` and retry.
