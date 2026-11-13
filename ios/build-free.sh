#!/usr/bin/env bash
set -euo pipefail

# Run on macOS with Xcode. No Apple ID, signing certificate or paid service.
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null || { echo 'This step requires macOS with Xcode.' >&2; exit 1; }
command -v xcodegen >/dev/null || { echo 'Install XcodeGen first: brew install xcodegen' >&2; exit 1; }

APP_ORIGIN="${APP_ORIGIN:-}"
if [[ -n "$APP_ORIGIN" ]]; then
  if [[ ! "$APP_ORIGIN" =~ ^https://[a-zA-Z0-9.-]+/?$ ]]; then
    echo 'APP_ORIGIN must be a plain HTTPS origin without credentials, path, query or fragment.' >&2
    exit 1
  fi
fi

xcodegen generate --spec ios/project-free.yml --project ios
# A fresh directory avoids mixing previous signed or widget-enabled builds.
BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nhoho-free.XXXXXX")"
xcodebuild -project ios/NhoHoFree.xcodeproj -scheme NhoHo \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath "$BUILD_ROOT/DerivedData" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= \
  NHOHO_APP_ORIGIN="$APP_ORIGIN" build

APP_PATH="$BUILD_ROOT/DerivedData/Build/Products/Release-iphoneos/NhoHo.app"
test -f "$APP_PATH/NhoHo" || { echo 'No iPhone app binary was produced.' >&2; exit 1; }
test ! -d "$APP_PATH/PlugIns" || { echo 'Free build must not embed widget extensions.' >&2; exit 1; }
mkdir -p "$BUILD_ROOT/Package/Payload" artifacts
cp -R "$APP_PATH" "$BUILD_ROOT/Package/Payload/NhoHo.app"
ditto -c -k --keepParent "$BUILD_ROOT/Package/Payload" artifacts/NhoHo-Free-unsigned.ipa
shasum -a 256 artifacts/NhoHo-Free-unsigned.ipa > artifacts/NhoHo-Free-unsigned.sha256
cat > artifacts/READ-ME.txt <<'TEXT'
This IPA is UNSIGNED. It cannot be installed by simply tapping it.
Use AltStore Classic/AltServer on Windows to sign and install it with your own Apple Account.
Free provisioning expires after 7 days; refresh the app before it expires.
No Apple Account password belongs in GitHub Actions or this repository.
This build has no App Groups, WidgetKit extension, APNs, iCloud or App Store distribution.
On launch, enter the HTTPS origin of your deployed Nho Ho web app if not preconfigured.
The app is a native WKWebView host; it still uses your hosted web UI and APIs.
TEXT
echo "Created artifacts/NhoHo-Free-unsigned.ipa (not signed or installed)."
