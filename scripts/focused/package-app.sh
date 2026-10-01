#!/bin/bash
# Build a local, ad-hoc signed app without changing the installed upstream application.
set -eo pipefail
cd "$(dirname "$0")/../.."

focused_configuration="${1:-release}"
case "$focused_configuration" in debug|release) ;; *) echo 'Usage: package-app.sh [debug|release]' >&2; exit 2 ;; esac
focused_sdk_path="$(scripts/focused/sdk-path.sh)"
focused_sdk="$(/usr/libexec/PlistBuddy -c 'Print :Version' "$focused_sdk_path/SDKSettings.plist")"
if [[ "${focused_sdk%%.*}" -lt 26 ]]; then
    echo 'Packaging requires a macOS 26 or newer SDK.' >&2
    exit 1
fi

# Record the real SDK version so AppKit enables native Liquid Glass rendering.
swift build --configuration "$focused_configuration" --sdk "$focused_sdk_path" -j 4 \
    -Xlinker -platform_version -Xlinker macos -Xlinker 26.0 -Xlinker "$focused_sdk"
focused_bin="$(swift build --configuration "$focused_configuration" --show-bin-path)"
focused_app="$PWD/dist/easydict-lite.app"
mkdir -p "$focused_app/Contents/MacOS" "$focused_app/Contents/Resources"
cp "$focused_bin/easydict-lite" "$focused_app/Contents/MacOS/easydict-lite"
cp Easydict/App/Info.plist "$focused_app/Contents/Info.plist"
cp Easydict/App/AppIcon.icns "$focused_app/Contents/Resources/AppIcon.icns"
for focused_resource in "$focused_bin"/*.bundle; do
    [[ -d "$focused_resource" ]] || continue
    focused_name="$(basename "$focused_resource")"
    rm -rf "$focused_app/Contents/Resources/$focused_name"
    cp -R "$focused_resource" "$focused_app/Contents/Resources/"
done
# Stable local identity helps preserve TCC authorization between local rebuilds.
codesign --force --sign - --identifier org.easydict.focused \
    --requirements '=designated => identifier "org.easydict.focused"' "$focused_app"
codesign --verify --deep --strict "$focused_app"
focused_archive="$PWD/dist/easydict-lite.zip"
ditto -c -k --sequesterRsrc --keepParent "$focused_app" "$focused_archive"
printf 'Built %s\nPackaged %s\n' "$focused_app" "$focused_archive"
