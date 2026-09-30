#!/bin/bash
# Run the retained Swift Testing suites, including on a CLT-only installation.
set -eo pipefail
cd "$(dirname "$0")/../.."
focused_developer="$(xcode-select -p)"
focused_macros="$focused_developer/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
focused_sdk_path="$(scripts/focused/sdk-path.sh)"
if [[ "$focused_developer" == *CommandLineTools* && -f "$focused_macros" ]]; then
    exec swift test --sdk "$focused_sdk_path" -j 4 -Xswiftc -load-plugin-library -Xswiftc "$focused_macros" "$@"
fi
exec swift test --sdk "$focused_sdk_path" -j 4 "$@"
