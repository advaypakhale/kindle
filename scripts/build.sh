#!/bin/sh
# Cross-compiles device helpers into device/usr/local/bin with Zig.
# The device runs glibc 2.20 on soft-float ARMv7. Avoid referencing libc data
# symbols such as stderr: Zig's copy relocations for them crash that loader.
set -e
cd "$(dirname "$0")/.."
zig=${ZIG:-zig}
mkdir -p device/usr/local/bin
"$zig" cc -target arm-linux-gnueabi.2.20 -mcpu=cortex_a9 -Os -s \
	-o device/usr/local/bin/blanketd device/src/blanketd.c -ldl
