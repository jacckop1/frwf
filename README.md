# KiraLocket

Clean-room, standalone Objective-C dynamic library for Locket.

## GitHub Actions build

The repository is ready to build without adding any secrets:

1. Upload the **contents of this folder** to a GitHub repository. Keep the hidden `.github` folder.
2. Open the repository's **Actions** tab.
3. Select **Build KiraLocket Dylib**.
4. Press **Run workflow**.
5. After the run succeeds, download the `KiraLocket-arm64-...` artifact.

The artifact contains:

- `KiraLocket.dylib` — standalone, ad-hoc-signed arm64 binary.
- `KiraLocket.plist` — filter for `com.locket.Locket`.
- `KiraLocket-Injection.zip` — dylib, plist, and build information together.
- `BUILD_INFO.txt` — architecture and linked-library report.
- `SHA256SUMS.txt` — integrity hashes.

The GitHub-hosted macOS runner supplies Xcode. The workflow installs Theos, builds the source, verifies the arm64 slice, and rejects output linked to CydiaSubstrate, Substitute, or libhooker.

## Local build on macOS

Install Xcode and Theos, set `THEOS`, then run:

```sh
./scripts/ci-build.sh
```

The ready files will be written to `dist/`.

## Target and compatibility

- Target bundle: `com.locket.Locket`
- Static compatibility reference: Locket `2.56.1`
- Minimum deployment target: iOS 14
- Architecture: `arm64`
- Build style: plain dynamic library using Objective-C runtime APIs
- No Logos directives and no hook-framework link dependency

`arm64` is intentional: Locket is an App Store application and uses the regular arm64 ABI even on arm64e-capable devices. This also makes the output more reliable for IPA injection.

## Included features

- Local settings panel injected into Locket settings.
- Face ID, Touch ID, or device-passcode app lock.
- Optional authentication before opening tweak settings.
- Floating gallery helper on the camera screen.
  - It triggers an already-visible native Locket upload button when one is found.
  - Its fallback picker supports selecting an image or video, then opens the iOS share sheet.
- Adaptive runtime class lookup and retry logic.
- Local `NSUserDefaults` storage.

## Explicitly excluded

- Gold or subscription unlocking.
- Purchase-response or entitlement modification.
- Ad hiding or ad-SDK interference.
- Locket server-check bypasses.
- Licensing, activation codes, telemetry, or remote kill switches.
- Location spoofing.
- Account-session or Keychain export.
- SATLocket source code, assets, names, URLs, or cryptographic material.

## Important limitation

The fallback gallery picker does not privately call hidden Locket upload APIs. A real in-app upload occurs only when the helper detects and triggers Locket's own visible upload control. Otherwise, the selected media is passed to the standard iOS share sheet.

## Repository structure

```text
.github/workflows/build.yml   GitHub Actions workflow
scripts/ci-build.sh           Build, sign, verify, and package output
scripts/validate-source.sh    Local-only and standalone dependency checks
layout/                       Rootless package filter layout
KiraEntry.m                   Dynamic-library entry point
KiraRuntime.m                 Runtime class discovery and UI injection
KiraGalleryCoordinator.m      Gallery fallback picker
KiraLockManager.m             LocalAuthentication lock
KiraSettingsViewController.m  Local settings UI
Makefile                      Theos standalone library build
```

## GitHub web-upload compatibility

The workflow does not rely on Unix executable bits being preserved. It runs the scripts through Bash and restores their executable permissions automatically, so uploading the repository from Windows or through GitHub's browser interface is supported.

## Why there is no `Tweak.xm`

`Tweak.xm` is normally used for Logos hooks and usually brings a Substrate-style hook dependency. This repository is intentionally built as a standalone injected dylib. `KiraEntry.m` contains the constructor entry point and `KiraRuntime.m` installs hooks with the Objective-C runtime, so a `Tweak.xm` file is not required.
