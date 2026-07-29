## 1.1.4

- Fixed the ARC compile failure in `KiraRuntime.m`: `capturing 'attemptInstall' strongly in this block is likely to lead to a retain cycle`.
- Replaced the self-referencing retry block with the `KLAttemptRuntimeInstall` helper function.
- Kept the same 15-attempt, one-second class-discovery retry behavior without suppressing compiler diagnostics.

## 1.1.3

- Fixed GitHub Actions startup validation failure: `runner.temp` is not available in `jobs.<job_id>.env`.
- Set `THEOS` to the writable external path `/tmp/theos`, keeping Theos outside the repository source scan.
- The cache and build steps continue to use the same `THEOS` environment variable.

# Changelog

## 1.1.2

- Fixed the false `Unexpected Logos/Substrate dependency detected` failure.
- Source validation now scans only KiraLocket project files, not the downloaded Theos toolchain or build cache.
- Moved the Theos installation to the GitHub runner temporary directory so it is outside the repository workspace.
- Added `.theos-toolchain/` to `.gitignore` for local builds.
- Clarified that `KiraEntry.m` replaces the usual `Tweak.xm` entry point because this build intentionally uses Objective-C runtime hooks without Logos or Substrate.

## 1.1.1

- Fixed GitHub Actions `Permission denied` when scripts are uploaded through the GitHub web interface or Windows.
- The workflow now restores script permissions and invokes the build script explicitly with Bash.
- The build script invokes source validation with Bash, so nested scripts do not depend on executable file mode.
- Added `.gitattributes` to keep shell scripts on LF line endings.

## 1.1.0

- Converted the source from a Logos-style tweak target to a standalone Theos library target.
- Renamed the entry source from `Tweak.xm` to `KiraEntry.m`.
- Added a GitHub Actions macOS build workflow.
- Added automatic ad-hoc signing and architecture verification.
- Added a linked-library check that rejects Substrate, Substitute, and libhooker dependencies.
- Added ready-to-inject ZIP and SHA-256 output generation.
- Added source validation for accidental networking, licensing, or Logos code.
