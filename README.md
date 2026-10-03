# LPAQ_MODS

Speed-optimized builds of the LPAQ file compressors **lpaq8** and **lpaq9m**, with
added `stdin`/`stdout` support.

Two things this repository is built around:

1. **Bit-compatible output.** Every archive produced here is **byte-identical** to the
   one produced by the corresponding original upstream binary, at every compression
   option. The optimizations never change what comes out, only how fast it comes out.
2. **Stream-friendly I/O.** `-` as the input or output file name means `stdin`/`stdout`,
   so `lpaq8`/`lpaq9m` drop into shell pipelines.

On top of that, the enhanced builds are **1.68x faster geometric-mean** than upstream
(1.82x average), verified on a 40-case corpus.

---

## Layout

| Path | What it is |
| --- | --- |
| `lpaq8.cpp`, `lpaq9m.cpp` | **The sources.** These are what you edit and what gets built. |
| `original/` | **Untouched upstream** sources, original `.exe` binaries and `readme.txt` files. Never modified; used as the compatibility oracle. |
| `build/` | Final binaries: `lpaq8.exe` / `lpaq9m.exe` (Windows PE) and `lpaq8` / `lpaq9m` (Linux ELF x86-64). |
| `build_lpaq8.bat`, `build_lpaq9m.bat` | Windows build scripts (one binary each). |
| `build_lpaq8.sh`, `build_lpaq9m.sh` | POSIX/Linux build scripts (one binary each). |
| `build.ps1` | Windows build script that produces **both** binaries in one run. |
| `comparison.csv`, `comparison.png`, `comparison.svg` | Benchmark data and charts (see [Performance](#performance)). |
| `LICENSE` | GPL version 2 or later, with upstream attribution. |

## Usage

```
lpaq8 N input output        compress      (N = 0..9, memory option)
lpaq8 d input output        decompress    (must use the same N)
```

Use `-` in place of a file name to mean **`stdin` on input** and **`stdout` on output**.

```sh
# file -> file
lpaq8 7 file.txt out.lpq

# the pipeline use case: stdin -> stdout
cat file.txt | lpaq8 7 - - > out.lpq

# stdin -> file, and file -> stdout
lpaq8 7 - out.lpq
lpaq8 7 file.txt - > out.lpq

# decompress stdin -> stdout
lpaq8 d - - < out.lpq > file.txt
```

The same forms apply to `lpaq9m`. Passing `d` as the first argument selects
decompression.

### Things worth knowing

- **Archives go to stdout; everything else goes to stderr.** The result report
  (`200000 -> 671 in 0.088 sec. using 102 MB memory`), usage text and error messages are
  all written to stderr, so `lpaq8 7 - - > out.lpq` yields a clean archive and nothing
  else. Nothing ever writes to a closed `stdout`.
- **Reading from `stdin` buffers the whole input in memory.** The LPAQ archive header
  records the input length *before* compression starts, so a non-seekable stream cannot
  simply be read past and then rewound. When the input is `stdin`, it is slurped into
  memory and then served through the normal path. Peak memory is therefore roughly
  `input size + compression memory`.
- **Compression from `stdin` produces the same bytes as from a file.** This is verified
  bit-for-bit in the test suites, not just assumed.
- On Windows the standard streams are switched to binary mode, so no newline
  translation can corrupt an archive.

## Building

### Windows

```bat
build_lpaq8.bat
build_lpaq9m.bat
```

or both at once:

```powershell
pwsh -File build.ps1
```

Produces `build\lpaq8.exe` and `build\lpaq9m.exe`.

Each script picks the compiler that measured fastest for that program and falls back to
the other one if it is missing:

| Program | Preferred | Fallback | Needs on `PATH` |
| --- | --- | --- | --- |
| `lpaq8` | `g++` | — | MinGW-w64 (`g++`) |
| `lpaq9m` | `clang++` | `g++` | LLVM (`clang++`), MinGW-w64 |

Force a specific compiler with `set LPAQ8_CXX=clang++` / `set LPAQ9M_CXX=g++`, or
`pwsh -File build.ps1 -Cxx8 clang++ -Cxx9m g++`.

Verified with MinGW-w64 g++ 14.2.0 and LLVM clang++ 21.1.0 (`--target=x86_64-w64-mingw32`
is added automatically for clang). The clang build emits ~270 upstream style warnings
(`>>` precedence inside macros, assignment used as a condition); they are pre-existing in
the upstream sources and are not errors.

### Linux / POSIX

```sh
sh build_lpaq8.sh
sh build_lpaq9m.sh
```

Produces `build/lpaq8` and `build/lpaq9m`. Same per-program compiler selection as above,
and it honors `CXX` and `CXXFLAGS`:

```sh
CXX=g++ sh build_lpaq9m.sh                              # force the fallback compiler
CXXFLAGS="-O2 -march=x86-64 -s" sh build_lpaq8.sh       # explicit flag set
```

Verified with g++ 13.3.0 and clang 18.1.3 on Ubuntu (ELF 64-bit x86-64).

### Compiler flags

All five scripts use the same validated flag set:

```
-O2 -march=x86-64 -s
```

Everything below was measured with interleaved, shuffled runs (median of 9–15 reps per
file) and **every variant that built successfully produced byte-identical archives**, so
these are pure speed comparisons:

| Variant | Result |
| --- | --- |
| `-O2` (chosen) | Baseline optimum. |
| `-O3`, `-Ofast`, `-Os`, `-Oz` | Neutral to slower. `-O3` is *not* an upgrade here. |
| `-march=native` | **Regression**, most visibly on `lpaq9m`. Rejected. |
| `-march=x86-64-v2`, `-march=x86-64-v3` | Neutral to slower; also cost portability. |
| `-mavx2`, `-mprefer-vector-width=512` | Neutral. |
| `-flto`, `-funroll-loops`, `-fomit-frame-pointer` | Neutral to slower. |
| PGO (`-fprofile-generate` / `-fprofile-use`) | No gain over plain `-O2`; actively harmful on `lpaq8`. |
| `-DNDEBUG` | **No-op** — see below. |
| Large pages | Unavailable on the test machine (`VirtualLock` error 1453, `MEM_LARGE_PAGES` error 1314). |

Compiler choice turned out to matter far more than any flag:

| Program | `clang++` vs `g++` | Chosen |
| --- | --- | --- |
| `lpaq8` | clang is **8%–13% slower** | `g++` |
| `lpaq9m` | clang is **4%–6% faster** | `clang++` |

## What changed relative to upstream

Diff size: `lpaq8` +318/-74 lines, `lpaq9m` +321/-87 lines.

### New functionality

- `-` for `stdin`/`stdout`, with the in-memory stdin buffer described above
  (`slurp_stdin()`, `raw_read()`, `raw_write()`), so the input path works unchanged for
  both files and pipes.
- Explicit byte counters (`io_raw_in`, `io_cmp_bytes`, `io_arch_in`, `io_out_bytes`)
  instead of `ftell()`. `ftell()` is meaningless on a pipe, which is exactly why the
  report used to be unusable in pipeline mode; counting bytes as they move also counts
  the 9-byte archive header, which bypasses the I/O buffers.
- All diagnostics moved to `stderr`, prefixed with the program name.

### Speed work (output-neutral)

- **lpaq8:** the 8192-entry `calcfails` lookup table replaced with direct scalar
  comparisons (`cf1`, `cf3`), which the compiler can keep in registers.
- **lpaq9m:** the large `calcfails` table replaced with compact `cf1[8]` / `cf3[8]`
  arrays.
- `stretch_t`, `dt` and `dta` narrowed from `int` to `short`, which is safe because the
  values are bounded well within 16 bits.
- Archive I/O goes through explicit 64 KiB output / 16 KiB input buffers instead of
  per-byte stdio calls, plus assorted hash-table, match-model, prefetch and layout
  tweaks.

None of this changes the compressed bitstream. That is asserted by the gates below,
which compare SHA-256 digests against the untouched upstream binaries.

## Verification

All gates below were run against **this** build, comparing it to the pristine binaries
in `original/`:

| Gate | Coverage | Result |
| --- | --- | --- |
| Bit-identity + cross-compatibility | whole corpus, options 4/5/6, both programs, both directions | `checks=20 failures=0` — `BIT-IDENTICAL + CROSS-COMPATIBLE` |
| Windows stream matrix (`-` in/out, all 4 combinations, empty/1-byte/binary/text/self inputs, options 1/5/6) | 45 checks per option per binary, 6 runs total | **270 passed, 0 failed** |
| Compatibility + timing | 40 runs, options 5/6 | `ALL PASS` |
| Native Linux stream matrix | stdin/stdout, options 1/5 | `116 passed, 0 failed` |
| Windows/Linux archive identity | Windows PE vs Linux ELF output | `fail=0` |

Cross-compatibility is checked in both directions: archives from the original binaries
are decompressed by these builds (and by these builds reading from a pipe), and
archives produced through a pipe by these builds are decompressed by the **original**
binaries.

## Performance

`comparison.csv` holds the raw data; `comparison.png` / `comparison.svg` chart it.

Methodology: 10 input files × 2 programs × 2 options (5 and 6) = **40 cases**,
best of **5** wall-clock runs each, compressing file-to-file on Windows.
`Ratio = enhanced_time / original_time`, so **`< 1.0` means faster**;
`Speedup = original_time / enhanced_time`, so **`> 1.0` means faster**.

| Metric | Value |
| --- | --- |
| Compressed sizes identical to upstream | **40 / 40** |
| Round-trips verified | **40 / 40** |
| Average ratio (enhanced / upstream) | **0.6342** |
| Average speedup | **1.8179x** |
| **Geometric-mean speedup** | **1.6840x** |
| Range | 0.981x – 3.975x |

Highlights and caveats, honestly:

- `lpaq8` on text and executables is where the work pays off: **3.98x** on `bin.exe` and
  **3.38x** on `text.txt`.
- `lpaq9m` gains more modestly, typically **1.0x – 1.6x**.
- **`zeros.bin` with `lpaq9m` is the one regression, ~2% slower** (0.98x). Highly
  compressible input almost never reaches the code the optimization targets, and the
  smaller `cf1`/`cf3` arrays cost a little on that path. `lpaq8` on the same input is
  2.31x faster, so it is specific to `lpaq9m` plus highly compressible data.
- Wall-clock numbers vary between runs on a shared machine; re-run the benchmark
  rather than comparing small differences across sessions.

## License

GPL version 2 or later (`GPL-2.0-or-later`). See [`LICENSE`](LICENSE).

Upstream copyright: `Copyright (C) 2007 Matt Mahoney, Alexander Ratushnyak` (lpaq8) and
`Copyright (C) 2007-2009 Matt Mahoney, Alexander Ratushnyak` (lpaq9m). The original,
unmodified upstream files are preserved under `original/` and carry the same license.
