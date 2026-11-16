# Vendored AMCoreAudio (bitgapp fork, "3.5")

eqMac depends on a fork of [AMCoreAudio](https://github.com/rnine/AMCoreAudio) (MIT, © Ruben Nine)
that was published at `github.com/bitgapp/AMCoreAudio`. That repository has since been deleted,
which made `pod install` impossible for this project.

This directory contains that fork's sources exactly as of commit
`b312d1509ef863dea3ca56cfa3f57451de4ff721` (2021-11-11), the commit pinned by upstream eqMac's
Podfile. The commit is still reachable through the upstream repository's fork network.

Local changes:
- `AMCoreAudio.podspec`: deployment target raised to macOS 12.0 (the minimum supported by
  current Xcode SDKs) and `source` pointed at the reachable commit. The pod is consumed via
  `:path`, so `source` is informational only.

- `Source/`: `import CoreAudio.AudioHardwareBase` replaced with `import CoreAudio` in five
  files. The macOS 27 SDK folded `AudioHardwareBase.h` into the `CoreAudio.AudioHardware`
  submodule, so the old submodule name no longer resolves. No other source changes.

See `LICENSE.md`.
