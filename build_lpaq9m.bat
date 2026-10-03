@echo off
REM build_lpaq9m.bat -- build lpaq9m.exe into .\build
REM
REM Validated flags (measurements in README.md, "Compiler flags"):
REM   -O2          optimum; -O3/-Ofast measured neutral-to-worse
REM   -march=x86-64 portable baseline; -march=native measured SLOWER here
REM   -s           strip symbols
REM
REM lpaq9m is ~6% faster under clang++ than g++, so clang++ is the default
REM when it is installed.  Overrides:
REM   set LPAQ9M_CXX=g++       force the other compiler
REM
REM Assertions are already compiled out by the source (it defines NDEBUG before
REM including <assert.h>); -DNDEBUG would be a no-op. To build with assertions,
REM comment out the "#define NDEBUG" line in lpaq9m.cpp.
setlocal
set "ROOT=%~dp0"
set "BUILD=%ROOT%build"
set "SRC=%ROOT%lpaq9m.cpp"
set "OUT=%BUILD%\lpaq9m.exe"

if not defined LPAQ9M_CXX (
  where clang++ >nul 2>nul
  if errorlevel 1 (set "LPAQ9M_CXX=g++") else (set "LPAQ9M_CXX=clang++")
)
where "%LPAQ9M_CXX%" >nul 2>nul
if errorlevel 1 (
  echo ERROR: '%LPAQ9M_CXX%' not found in PATH.
  echo        Install MinGW-w64 x86_64 and add its bin directory to PATH.
  exit /b 1
)

REM clang needs an explicit MinGW target; g++ already targets it.
set "TARGETARG="
if /i "%LPAQ9M_CXX%"=="clang++" set "TARGETARG=--target=x86_64-w64-mingw32"

if not exist "%BUILD%" mkdir "%BUILD%"

echo Cleaning previous build...
del /q "%OUT%" >nul 2>nul

echo Building lpaq9m.exe with %LPAQ9M_CXX% ...
%LPAQ9M_CXX% -O2 -march=x86-64 -s %TARGETARG% -o "%OUT%" "%SRC%"
if errorlevel 1 (
  echo ERROR: build failed.
  exit /b 1
)

echo Done: %OUT%
endlocal