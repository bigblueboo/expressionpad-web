#!/bin/sh
# Run the core test suite with a compiler and SDK from the same selected Xcode.
set -e
cd "$(dirname "$0")"

if [ -n "${XCODE:-}" ]; then
  DEVELOPER_DIR="$XCODE/Contents/Developer"
  export DEVELOPER_DIR
fi

SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
SWIFT=$(xcrun --find swift)

"$SWIFT" --version
echo "SDK: $SDKROOT"
exec "$SWIFT" test -Xswiftc -sdk -Xswiftc "$SDKROOT" "$@"
