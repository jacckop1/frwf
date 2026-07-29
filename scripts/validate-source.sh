#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

required=(
  Makefile
  KiraEntry.m
  KiraRuntime.m
  KiraSettingsViewController.m
  KiraLockManager.m
  KiraGalleryCoordinator.m
  KiraUtilities.m
  KiraLocket.plist
)

for file in "${required[@]}"; do
  [[ -f "$file" ]] || { echo "Missing required file: $file" >&2; exit 1; }
done

# Only inspect this project's own source files. Never recursively scan Theos,
# build products, caches, or vendored framework headers.
project_sources=(
  KiraEntry.m
  KiraRuntime.m
  KiraRuntime.h
  KiraSettingsViewController.m
  KiraSettingsViewController.h
  KiraLockManager.m
  KiraLockManager.h
  KiraGalleryCoordinator.m
  KiraGalleryCoordinator.h
  KiraUtilities.m
  KiraUtilities.h
  KiraConstants.h
)

for file in "${project_sources[@]}"; do
  [[ -f "$file" ]] || { echo "Missing source file: $file" >&2; exit 1; }
done

# The clean-room project is intentionally local-only. Fail CI if networking or
# known licensing-server strings are accidentally introduced into project code.
if grep -nE \
  'NSURLSession|NSURLConnection|CFNetwork|sat-dev\.com|sat-vip\.com|performLoginCheck|cert_number|expiration_date' \
  "${project_sources[@]}"; then
  echo "Unexpected networking or licensing-related code detected." >&2
  exit 1
fi

# This is a plain Objective-C runtime dylib. It intentionally has no Logos file
# and no Substrate hook dependency. KiraEntry.m is the constructor entry point.
if grep -nE \
  '%hook|%ctor|%init|substrate\.h|CydiaSubstrate|MSHook' \
  "${project_sources[@]}"; then
  echo "Unexpected Logos/Substrate dependency detected in project source." >&2
  exit 1
fi

echo "Source validation passed."
