# mupdf

Build the [MuPDF](https://mupdf.com/) static C libraries needed to link MuPDF into a Go project via cgo.

[MuPDF](https://mupdf.com/) ships as C source rather than prebuilt binaries, and the stock build includes features,
fonts, and third-party symbols that aren't wanted when embedding it in a Go program. This repository wraps the MuPDF
build with a single script that downloads a pinned version, trims and patches the source, compiles it, and packages a
single static library plus headers ready to be linked.

Currently builds **MuPDF 1.27.2**.

## What you get

Running the build produces a `dist/` directory:

```
dist/
├── include/mupdf/...                 # public MuPDF headers
└── lib/libmupdf_<os>_<arch>.a        # single combined static library
```

The library name encodes the target so artifacts for differenßt platforms can live side by side, for example:

| Platform        | Library file               |
| --------------- | -------------------------- |
| macOS (Apple)   | `libmupdf_darwin_arm64.a`  |
| macOS (Intel)   | `libmupdf_darwin_amd64.a`  |
| Linux x86-64    | `libmupdf_linux_amd64.a`   |
| Linux ARM64     | `libmupdf_linux_arm64.a`   |
| Windows x86-64  | `libmupdf_windows_amd64.a` |
| Windows ARM64   | `libmupdf_windows_arm64.a` |

MuPDF's own static library and its bundled third-party dependencies are merged into this one `.a` so a downstream
project only has to link a single file.

## Building

```sh
./build.sh
```

The script will:

1. Download the MuPDF source tarball (cached as `mupdf-<version>-source.tgz`).
2. Extract and patch it (see [Notes](#notes)).
3. Compile with a trimmed feature set.
4. Merge the results into `dist/lib/libmupdf_<os>_<arch>.a` and copy the headers.

### Options

```
./build.sh [options]
  -c, --clean   Remove the dist and build directories (no build)
  -C, --CLEAN   Remove all downloaded and built files and directories (no build)
  -h, --help    Show help
```

### Requirements

- A C toolchain (`gcc`/`clang`) and `make`
- `bash`, `curl`, `tar`, `ar`, `sed`
- **Windows:** [MSYS2/MinGW](https://www.msys2.org/) (`mingw32-make`). On Windows/ARM64 a native
  `aarch64-w64-mingw32-gcc` is required, because the default MinGW `gcc` emits x86 code; point the script at it with the
  `CC` environment variable.

### Supported targets

`darwin`, `linux`, and `windows` on `amd64` and `arm64`. The architecture and OS are detected automatically from
`uname`.

## Continuous integration

[`.github/workflows/build.yml`](.github/workflows/build.yml) runs `build.sh` across macOS, Linux, and Windows runners
(Intel and ARM) on every push and pull request, uploading each platform's `dist/` as a build artifact.

## Notes

To keep the resulting library small and avoid symbol collisions when linking alongside other libraries (such as Skia,
which bundles its own copy of libjpeg), the build:

- Disables unused MuPDF features: XPS, SVG, CBZ, HTML, EPUB, JavaScript, OCR, DOCX/ODT output, and spot rendering.
- Drops the bundled CJK and Droid/Noto/SIL/Han fonts (`TOFU` / `TOFU_CJK`).
- Renames the bundled libjpeg symbols (`jpeg_*` → `jpegx_*`, etc.) to avoid clashing with another copy of libjpeg in the
  final binary.
- Shortens `thirdparty` paths to `tp` so command lines stay within Windows limits.

## License

MuPDF is distributed under the GNU Affero General Public License v3. This repository carries the same
[LICENSE](LICENSE). See [mupdf.com/license](https://mupdf.com/licensing/) for commercial licensing options.
