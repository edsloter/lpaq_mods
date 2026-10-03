# Build lpaq8.exe and lpaq9m.exe into .\build
#
# Validated flags (measurements in README.md, "Compiler flags"):
#   -O2          optimum; -O3/-Ofast measured neutral-to-worse
#   -march=x86-64 portable baseline; -march=native and -march=x86-64-v3 measured slower
#   -s           strip symbols
#
# NOTE on asserts: lpaq8.cpp/lpaq9m.cpp define NDEBUG *before* including
# <assert.h>, so assertions are already compiled out by the source itself and
# passing -DNDEBUG changes nothing (verified: identical object code). To build
# with assertions enabled, comment out the "#define NDEBUG" line in the source;
# no command-line switch can undo a #define in the source.
#
# Compilers: lpaq8 is ~7% faster under g++, lpaq9m ~6% faster under clang++,
# so each program gets its fastest compiler when installed, falling back to the
# other.  Override explicitly with -Cxx8 / -Cxx9m.
#
# Measured and REJECTED (all produced bit-identical archives, none faster):
#   -O3 -Ofast -Os -Oz -march=native -march=x86-64-v2/v3 -mavx2 -flto
#   -funroll-loops -fomit-frame-pointer -mprefer-vector-width=512
#   PGO (-fprofile-generate/-fprofile-use): no gain, harmful on lpaq8.
#
# -RejectedMarchNative only exists to reproduce the rejected -march=native run:
#   .\build.ps1 -RejectedMarchNative
param(
  [string]$OutDir = "$PSScriptRoot\build",
  [string]$Cxx8 = "",
  [string]$Cxx9m = "",
  [switch]$RejectedMarchNative
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# Clear read-only so the linker can overwrite previous outputs.
Get-ChildItem $OutDir -Filter *.exe -ErrorAction SilentlyContinue |
  ForEach-Object { $_.IsReadOnly = $false }

function Resolve-Compiler([string]$Explicit, [string[]]$Auto, [string]$Label) {
  if ($Explicit) {
    if (Get-Command $Explicit -ErrorAction SilentlyContinue) { return $Explicit }
    # An explicitly requested compiler is never silently substituted.
    throw ("{0}: requested compiler '{1}' not found in PATH." -f $Label, $Explicit)
  }
  foreach ($c in $Auto) {
    if (Get-Command $c -ErrorAction SilentlyContinue) { return $c }
  }
  throw ("{0}: no usable C++ compiler found (tried {1})." -f $Label, ($Auto -join ', ')) +
        " Install MinGW-w64 x86_64 (g++) and/or LLVM (clang++) and add it to PATH."
}

$cxx8  = Resolve-Compiler $Cxx8  @('g++')             'lpaq8'
$cxx9m = Resolve-Compiler $Cxx9m @('clang++', 'g++')  'lpaq9m'

# clang needs an explicit MinGW target; g++ already targets it.
# NB: assign arrays directly -- an `if` used as an expression unrolls a
# single-element array back to a string, and splatting a string enumerates chars.
$target8  = @()
$target9m = @()
if ((Split-Path -Leaf $cxx8)  -like 'clang*') { $target8  = @('--target=x86_64-w64-mingw32') }
if ((Split-Path -Leaf $cxx9m) -like 'clang*') { $target9m = @('--target=x86_64-w64-mingw32') }

$flags8  = @('-O2', '-march=x86-64', '-s')
$march9m = if ($RejectedMarchNative) { 'native' } else { 'x86-64' }
$flags9m = @('-O2', "-march=$march9m", '-s')

Write-Host "Building lpaq8.exe  with $cxx8 ..."
& $cxx8 @target8 @flags8 -o "$OutDir\lpaq8.exe" "$here\lpaq8.cpp"
if ($LASTEXITCODE -ne 0) { throw "lpaq8 build failed with $cxx8" }

Write-Host "Building lpaq9m.exe with $cxx9m (-march=$march9m) ..."
& $cxx9m @target9m @flags9m -o "$OutDir\lpaq9m.exe" "$here\lpaq9m.cpp"
if ($LASTEXITCODE -ne 0) { throw "lpaq9m build failed with $cxx9m" }

Write-Output "built lpaq8.exe with $cxx8, lpaq9m.exe with $cxx9m (-march=$march9m)"
Get-ChildItem $OutDir -Filter *.exe | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize