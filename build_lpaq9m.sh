#!/bin/sh
# build_lpaq9m.sh -- build lpaq9m into ./build
#
# Validated flags (measurements in README.md, "Compiler flags"):
#   -O2          optimum; -O3/-Ofast measured neutral-to-worse
#   -march=x86-64 portable baseline; -march=native measured SLOWER here
#   -s           strip symbols
#
# lpaq9m is ~6% faster under clang++ than g++, so clang++ is the default when
# it is installed.
#
# Assertions are already compiled out by the source (it defines NDEBUG before
# including <assert.h>), so -DNDEBUG would be a no-op. To build with assertions,
# comment out the "#define NDEBUG" line in lpaq9m.cpp.
#
# Overrides:
#   CXX=g++              force the other compiler
#   CXXFLAGS="..."       replace the flag set entirely (must stay bit-identical)
set -e

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
out="$here/build"
mkdir -p "$out"

if [ -z "$CXX" ]; then
  if command -v clang++ >/dev/null 2>&1; then CXX=clang++; else CXX=g++; fi
fi
command -v "$CXX" >/dev/null 2>&1 || {
  echo "ERROR: '$CXX' not found in PATH." >&2
  echo "       Install MinGW-w64 x86_64 (g++) or LLVM (clang++) and add it to PATH." >&2
  exit 1
}

default_flags="-O2 -march=x86-64 -s"
CXXFLAGS=${CXXFLAGS:-$default_flags}

echo "Cleaning previous build..."
rm -f "$out/lpaq9m"
echo "Building lpaq9m with $CXX $CXXFLAGS"
# shellcheck disable=SC2086
"$CXX" $CXXFLAGS -o "$out/lpaq9m" "$here/lpaq9m.cpp"

echo "Done: $out/lpaq9m"