#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

: "${THEOS:?THEOS must point to a Theos installation}"

bash ./scripts/validate-source.sh
rm -rf dist
mkdir -p dist

# Build the actual standalone dynamic library. FINALPACKAGE enables release
# optimizations in Theos where applicable.
make clean all FINALPACKAGE=1 messages=yes

DYLIB_PATH="$({ python3 - <<'PY'
from pathlib import Path
candidates = [p for p in Path('.theos').rglob('KiraLocket.dylib') if p.is_file()]
if not candidates:
    raise SystemExit('KiraLocket.dylib was not produced by Theos')
# Prefer the merged/final binary, which is normally the largest candidate.
print(max(candidates, key=lambda p: p.stat().st_size))
PY
} )"

cp "$DYLIB_PATH" dist/KiraLocket.dylib

# Convert the filter plist to XML for maximum injector compatibility.
plutil -convert xml1 -o dist/KiraLocket.plist KiraLocket.plist
plutil -lint dist/KiraLocket.plist

# Ad-hoc sign the dylib. IPA signing tools may replace this signature later.
codesign --force --sign - --timestamp=none dist/KiraLocket.dylib
codesign --verify --verbose=2 dist/KiraLocket.dylib

ARCH_LIST="$(lipo -archs dist/KiraLocket.dylib)"
echo "Architectures: $ARCH_LIST"
case " $ARCH_LIST " in
  *" arm64 "*) ;;
  *) echo "The output does not contain arm64." >&2; exit 1 ;;
esac

# A standalone sideload dylib must not require a jailbreak hook framework.
if otool -L dist/KiraLocket.dylib | grep -Eqi 'CydiaSubstrate|libsubstrate|Substitute|libhooker'; then
  echo "The output unexpectedly links to a jailbreak hook framework:" >&2
  otool -L dist/KiraLocket.dylib >&2
  exit 1
fi

file dist/KiraLocket.dylib | tee dist/BUILD_INFO.txt
{
  echo
  echo "Architectures: $ARCH_LIST"
  echo "Built at (UTC): $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "Git commit: ${GITHUB_SHA:-local}"
  echo
  echo "Linked libraries:"
  otool -L dist/KiraLocket.dylib
} >> dist/BUILD_INFO.txt

(
  cd dist
  zip -9 KiraLocket-Injection.zip KiraLocket.dylib KiraLocket.plist BUILD_INFO.txt
  shasum -a 256 KiraLocket.dylib KiraLocket.plist KiraLocket-Injection.zip > SHA256SUMS.txt
)

echo "Build output:"
ls -lah dist
