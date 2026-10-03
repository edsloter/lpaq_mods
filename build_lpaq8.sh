#!/bin/sh
# build_lpaq8.sh -- build lpaq8 into ./build
#
# Validated flags (measurements in README.md, "Compiler flags"):
#   -O2          optimum; -O3/-Ofast measured neutral-to-worse
#   -march=x86-64 portable baseline; -march=native and -v3 measured slower
#   -s           strip symbols
#
# Assertions are already compiled out by the source (it defines NDEBUG before
# including <assert.h>), so -DNDEBUG would be a no-op. To build with assertions,
# comment out the "#define NDEBUG" line in lpaq8.cpp.
#
# Overrides:
#   CXX=clang++        use a different compiler (clang measured ~7% slower here)
#   CXXFLAGS="..."     replace the flag set entirely (must stay bit-identical)
set -e

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
out="$here/build"
mkdir -p "$out"

CXX=${CXX:-g++}
command -v "$CXX" >/dev/null 2>&1 || {
  echo "ERROR: '$CXX' not found in PATH." >&2
  echo "       Install MinGW-w64 x86_64 (g++) or LLVM (clang++) and add it to PATH." >&2
  exit 1
}

default_flags="-O2 -march=x86-64 -s"
CXXFLAGS=${CXXFLAGS:-$default_flags}

echo "Cleaning previous build..."
rm -f "$out/lpaq8"
echo "Building lpaq8 with $CXX $CXXFLAGS"
# shellcheck disable=SC2086
"$CXX" $CXXFLAGS -o "$out/lpaq8" "$here/lpaq8.cpp"

echo "Done: $out/lpaq8"