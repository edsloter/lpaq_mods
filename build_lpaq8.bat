@echo off
REM build_lpaq8.bat -- build lpaq8.exe into .\build
REM
REM Validated flags (measurements in README.md, "Compiler flags"):
REM   -O2          optimum; -O3/-Ofast measured neutral-to-worse
REM   -march=x86-64 portable baseline; -march=native and -v3 measured slower
REM   -s           strip symbols
REM
REM Assertions are already compiled out by the source (it defines NDEBUG before
REM including <assert.h>); -DNDEBUG would be a no-op. To build with assertions,
REM comment out the "#define NDEBUG" line in lpaq8.cpp.
REM
REM Overrides:
REM   set LPAQ8_CXX=clang++   use a different compiler (clang is ~7% slower here)
setlocal
set "ROOT=%~dp0"
set "BUILD=%ROOT%build"
set "SRC=%ROOT%lpaq8.cpp"
set "OUT=%BUILD%\lpaq8.exe"

if not defined LPAQ8_CXX set "LPAQ8_CXX=g++"
where "%LPAQ8_CXX%" >nul 2>nul
if errorlevel 1 (
  echo ERROR: '%LPAQ8_CXX%' not found in PATH.
  echo        Install MinGW-w64 x86_64 and add its bin directory to PATH.
  exit /b 1
)

REM clang needs an explicit MinGW target; g++ already targets it.
set "TARGETARG="
if /i "%LPAQ8_CXX%"=="clang++" set "TARGETARG=--target=x86_64-w64-mingw32"

if not exist "%BUILD%" mkdir "%BUILD%"

echo Cleaning previous build...
del /q "%OUT%" >nul 2>nul

echo Building lpaq8.exe with %LPAQ8_CXX% ...
%LPAQ8_CXX% -O2 -march=x86-64 -s %TARGETARG% -o "%OUT%" "%SRC%"
if errorlevel 1 (
  echo ERROR: build failed.
  exit /b 1
)

echo Done: %OUT%
endlocal