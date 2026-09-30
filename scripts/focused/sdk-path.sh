#!/bin/bash
# CLT's macOS 27 SDK declares SwiftUI macros whose plugin ships only with Xcode.
# Prefer the installed macOS 26 SDK on CLT; leave the user's selected toolchain unchanged.
set -eo pipefail
focused_developer="$(xcode-select -p)"
focused_path="$(xcrun --show-sdk-path)"
if [[ "$focused_developer" == *CommandLineTools* && -d "$focused_developer/SDKs/MacOSX26.sdk" ]]; then
    focused_path="$focused_developer/SDKs/MacOSX26.sdk"
fi
printf '%s\n' "$focused_path"
