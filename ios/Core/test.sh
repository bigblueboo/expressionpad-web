#!/bin/sh
# Run the core test suite on macOS without needing `sudo xcodebuild -license`:
# invokes the Xcode toolchain's SwiftPM directly (no xcrun license shim) and
# points it at the platform's swift-testing framework.
#
# Once the Xcode license is accepted, plain `swift test` works too.
set -e
cd "$(dirname "$0")"

XCODE=${XCODE:-/Users/cdeck/Applications/Xcode-16.4.0.app}
TOOLCHAIN="$XCODE/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
XCPLAT="$XCODE/Contents/Developer/Platforms/MacOSX.platform/Developer"

exec "$TOOLCHAIN/swift-test" --disable-xctest --enable-swift-testing \
  -Xswiftc -F -Xswiftc "$XCPLAT/Library/Frameworks" \
  -Xlinker -F -Xlinker "$XCPLAT/Library/Frameworks" \
  -Xlinker -rpath -Xlinker "$XCPLAT/Library/Frameworks" \
  "$@"
