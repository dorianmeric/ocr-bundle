# OCR Bundle

A **portable, self-contained Windows OCR & PDF-processing toolkit** — no
installation required. Everything runs directly from the bundle folder.

## Table of Contents

- [What's Inside](#whats-inside)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Installation](#installation)
- [Scripts Reference](#scripts-reference)
  - [`ocr-pdf.bat` — OCR a Single PDF](#ocr-pdfbat--ocr-a-single-pdf)
  - [`ocr-folder.bat` — Batch OCR a Folder](#ocr-folderbat--batch-ocr-a-folder)
  - [`downsample-pdf.bat` — Downsample a Single PDF](#downsample-pdfbat--downsample-a-single-pdf)
  - [`downsample-folder.bat` — Batch Downsample a Folder](#downsample-folderbat--batch-downsample-a-folder)
  - [`clean_pycache.bat` — Clean Python Cache](#clean_pycachebat--clean-python-cache)
- [OCRmyPDF Options Reference](#ocrmypdf-options-reference)
- [Downsampling Options Reference](#downsampling-options-reference)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Vendored Component Versions](#vendored-component-versions)
- [Workflows](#workflows)
  - [Typical OCR Workflow](#typical-ocr-workflow)
  - [Bulk Processing Workflow](#bulk-processing-workflow)
- [Exit Codes](#exit-codes)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [License & Credits](#license--credits)

---

## What's Inside

| Component | Role | Bundled At |
|---|---|---|
| **[Tesseract OCR 5](https://github.com/tesseract-ocr/tesseract)** | OCR engine (English language data) | `tesseract\` |
| **[Ghostscript](https://www.ghostscript.com/)** | PDF rasterization, downsampling, and rewriting | `ghostscript\` |
| **[Python 3.13](https://www.python.org/)** + **[OCRmyPDF](https://ocrmypdf.readthedocs.io/)** | PDF OCR pipeline with deskew, rotation, and PDF/A output | `python\` |
| **[pypdfium2](https://github.com/pypdfium2-team/pypdfium2)** | PDFium-based PDF rendering & text extraction | `python\Lib\site-packages\` |
| **[Rich](https://github.com/Textualize/rich)** | Terminal output formatting (used by OCRmyPDF) | `python\Lib\site-packages\` |

The bundle is **relocatable**: all scripts derive paths from `%~dp0` (the
folder containing the script). You can move or rename the bundle folder and
everything still works. No system Python, Tesseract, or Ghostscript installation
is required.

---

## Quick Start

Open `cmd.exe` in the bundle root (or use `cmd /c` from PowerShell):

```bat
:: OCR a single PDF — output goes next to the input as <name>_ocr.pdf
ocr-pdf.bat C:\scans\document.pdf

:: OCR all PDFs in a folder tree
ocr-folder.bat C:\scans

:: Downsample images in a PDF to 72 DPI (dramatically shrinks file size)
downsample-pdf.bat C:\scans\large.pdf

:: Downsample every PDF in a folder tree
downsample-folder.bat C:\scans
```

The output PDFs are **searchable PDF/A documents** with embedded OCR text
layers.

---

## Requirements

- **Windows x64** — the bundled runtimes are 64-bit Windows binaries.
- **~1.5 GB** of free disk space for the full bundle.
- No administrator privileges required.
- No system PATH modifications required.
- No Python, Tesseract, or Ghostscript installation required.

---

## Installation

1. **Download or clone** this repository to any local folder:
   ```bat
   git clone https://github.com/dorianmeric/ocr-bundle.git
   ```
   Or download the ZIP from GitHub and extract it.

2. **Open a Command Prompt** (`cmd.exe`) in the bundle root folder.

3. **Run a script** (see [Quick Start](#quick-start) above).

That's it. There is no installer, no build step, and no configuration needed.

---

## Scripts Reference

### `ocr-pdf.bat` — OCR a Single PDF

Processes one PDF through OCRmyPDF with optimized defaults for scanned
documents.

```
Usage:
  ocr-pdf.bat input.pdf [output.pdf] [ocrmypdf options]

Examples:
  ocr-pdf.bat scan.pdf
  ocr-pdf.bat scan.pdf scan_ocr.pdf
  ocr-pdf.bat scan.pdf --force-ocr
  ocr-pdf.bat scan.pdf scan_ocr.pdf --force-ocr --deskew --rotate-pages
```

| Argument | Required | Description |
|---|---|---|
| `input.pdf` | Yes | Path to the source PDF file |
| `output.pdf` | No | Output path. Defaults to `<input>_ocr.pdf` next to the source |
| `[ocrmypdf options]` | No | Forwarded directly to OCRmyPDF (see [Options Reference](#ocrmypdf-options-reference)) |

**Default OCRmyPDF flags applied:**

| Flag | Value | Purpose |
|---|---|---|
| `--language` | `eng` | English OCR |
| `--force-ocr` | — | OCR every page even if text already present |
| `--deskew` | — | Straighten skewed pages |
| `--rotate-pages` | — | Auto-rotate pages to correct orientation |
| `--tesseract-timeout` | `0` | No timeout (handles large/complex pages) |
| `--optimize` | `3` | Aggressive PDF optimization |
| `--jpeg-quality` | `1` / `10` | JPEG quality (1 when no extra args, 10 with extra args) |
| `--jpeg-maxdpi` | `10` | Maximum DPI for JPEG recompression |
| `--clean` | — | Remove metadata and private data |
| `--pdfa-image-compression` | `jpeg` | JPEG compression for PDF/A images |
| `--output-type` | `pdfa` | Produce PDF/A compliant output |

> **Note:** When you pass extra OCRmyPDF options, JPEG quality defaults to 10
> instead of 1, giving you higher image quality in exchange for larger file size.

**From PowerShell:**
```powershell
cmd /c ".\ocr-pdf.bat C:\scans\input.pdf C:\scans\output.pdf"
```

---

### `ocr-folder.bat` — Batch OCR a Folder

Recursively finds all `.pdf` files under a folder and processes each one with
`ocr-pdf.bat`. Each file gets its own `_ocr.pdf` output next to the source.

```
Usage:
  ocr-folder.bat input_folder [ocrmypdf options]

Examples:
  ocr-folder.bat .
  ocr-folder.bat C:\docs\pdfs
  ocr-folder.bat C:\docs\pdfs --force-ocr
  ocr-folder.bat C:\docs\pdfs --force-ocr --deskew
```

| Argument | Required | Description |
|---|---|---|
| `input_folder` | Yes | Root folder to scan for PDFs (use `.` for current directory) |
| `[ocrmypdf options]` | No | Forwarded to `ocr-pdf.bat` for each file |

The script prints a summary at the end:

```
============================================================
Summary
============================================================
PDFs Found : 12
Succeeded  : 11
Failed     : 1
```

Exit code is non-zero if any file fails.

---

### `downsample-pdf.bat` — Downsample a Single PDF

Reduces PDF file size by downsampling embedded images using Ghostscript.
Useful for archiving scanned documents where high-DPI images aren't needed.

```
Usage:
  downsample-pdf.bat input.pdf [max_dpi] [jpeg_quality] [output.pdf]
  downsample-pdf.bat input.pdf [max_dpi] [output.pdf]

Examples:
  downsample-pdf.bat input.pdf
  downsample-pdf.bat input.pdf 72
  downsample-pdf.bat input.pdf 72 60
  downsample-pdf.bat input.pdf 72 output.pdf
  downsample-pdf.bat input.pdf 72 60 output.pdf
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `input.pdf` | Yes | — | Path to the source PDF |
| `max_dpi` | No | `72` | Maximum DPI for downsampled images |
| `jpeg_quality` | No | `60` | JPEG quality (0–100, higher = better quality) |
| `output.pdf` | No | `low-quality\<name>_<dpi>dpi.pdf` | Output file path |

**Ghostscript settings applied:**

- Color/grayscale images: bicubic downsampling to `max_dpi`
- Monochrome images: subsample downsampling to `max_dpi`
- All images re-encoded as JPEG (DCT) at the specified quality
- Fonts are compressed and subset to used glyphs
- Duplicate image streams are detected and reused
- PDF compatibility level: 1.6

After completion, the script prints a size comparison:

```
Input Size : 45.23 MB
Output Size: 2.87 MB
Reduction : 93.65%
```

**From PowerShell:**
```powershell
cmd /c ".\downsample-pdf.bat C:\scans\large.pdf 72 60 C:\scans\small.pdf"
```

---

### `downsample-folder.bat` — Batch Downsample a Folder

Recursively finds all `.pdf` files under a folder and downsamples each one.
Skips files inside any folder named `low-quality` to avoid re-processing
generated output.

```
Usage:
  downsample-folder.bat input_folder [max_dpi] [jpeg_quality]

Examples:
  downsample-folder.bat .
  downsample-folder.bat C:\docs\pdfs 100
  downsample-folder.bat C:\docs\pdfs 100 60
```

| Argument | Required | Default | Description |
|---|---|---|---|
| `input_folder` | Yes | — | Root folder to scan (use `.` for current directory) |
| `max_dpi` | No | `72` | Maximum DPI for downsampled images |
| `jpeg_quality` | No | `60` | JPEG quality (0–100) |

Output files are placed in `low-quality\` subfolders next to each source PDF.
The summary includes a `Skipped` count for files that were excluded because
they already lived under a `low-quality` path.

---

### `clean_pycache.bat` — Clean Python Cache

Removes `__pycache__` directories and `.pyc`/`.pyo` files from the bundle to
reduce its size before packaging or distribution.

```
Usage:
  clean_pycache.bat [target_folder]

Examples:
  clean_pycache.bat
  clean_pycache.bat C:\ocr-bundle
```

| Argument | Required | Default | Description |
|---|---|---|
| `target_folder` | No | Bundle root | Folder to recursively clean |

> **Note:** After cleaning, OCRmyPDF will recompile bytecode on first run,
> which adds a small startup deloy. Only clean before archiving.

---

## OCRmyPDF Options Reference

All extra arguments after the output path (or after the input if output is
omitted) are forwarded directly to OCRmyPDF. Here are the most useful ones:

| Flag | Description |
|---|---|
| `--force-ocr` | OCR pages that already contain text |
| `--skip-text` | Skip pages that already have text |
| `--deskew` | Straighten skewed pages |
| `--rotate-pages` | Auto-detect and fix page orientation |
| `--remove-background` | Remove background noise from pages |
| `--clean` | Remove document metadata |
| `--optimize 0-3` | PDF optimization level (0=none, 3=aggressive) |
| `--pdfa-image-compression jpeg\|lossless` | Compression for PDF/A images |
| `--output-type pdfa\|pdf` | Output PDF type |
| `--skip-big N` | Skip OCR on images larger than N megapixels |
| `--tesseract-timeout N` | Seconds before Tesseract is interrupted (0=unlimited) |
| `--jpeg-quality N` | JPEG quality for recompressed images (0–100) |
| `--jpeg-maxdpi N` | Maximum DPI for JPEG recompression |
| `--language lang1+lang2` | OCR language(s) (requires additional tessdata) |

For the coplete reference, see the [OCRmyPDF
documentation](https://ocrmypdf.readthedocs.io/en/latest/).

---

## Downsampling Options Reference

### DPI Guide

| Max DPI | Use Case | Approximate Reduction |
|---|---|---|
| `72` | Email / web upload | 80–95% |
| `100` | Internal document storage | 60–80% |
| `150` | Archival with some detail | 40–60% |
| `200` | High-quality archival | 20–40% |
| `300` | Print-ready | Minimal |

### JPEG Quality Guide

| Quality | File Size | Visual Quality |
|---|---|
| `30` | Very small | Noticeable artifacts |
| `60` (default) | Small | Good for documents |
| `80` | Medium | Excellent for most uses |
| `100` | Large | Lossless JPEG appearance |

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                  ocr-folder.bat                   │
│         (recursively finds PDFs, delegates)       │
│                      │                            │
│                      ▼                            │
│                  ocr-pdf.bat                      │
│       (resolves paths, sets env, invokes:)        │
│                      │                            │
│         ┌────────────┼────────────┐               │
│         ▼            ▼            ▼               │
│   python\python.exe  tesseract\  ghostscript\     │
│   -m ocrmypdf        tesseract   bin\gswin64c     │
│                      .exe        .exe             │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│              downsample-folder.bat                │
│         (recursively finds PDFs, delegates)       │
│                      │                            │
│                      ▼                            │
│              downsample-pdf.bat                   │
│       (validates args, invokes Ghostscript)       │
│                      │                            │
│                      ▼                            │
│              ghostscript\bin\gswin64c.exe         │
│              (pdfwrite device, downsamping)      │
└──────────────────────────────────────────────────┘
```

- **`ocr-pdf.bat`** and **`downsample-pdf.bat`** are the single-file workhorses.
- **`ocr-folder.bat`** and **`downsample-folder.bat`** are thin wrappers that
  recurse through directories and delegate to the single-file scripts.
- All four scripts propagate exit codes so you can use them in CI/CD or batch
  pipelines.
- PowerShell users invoke scripts via `cmd /c ".\script.bat args"`.

---

## Directory Structure

```
ocr-bundle/
├── ocr-pdf.bat              # OCR single PDF (OCRmyPDF)
├── ocr-folder.bat           # OCR folder tree
├── downsample-pdf.bat       # Downsample single PDF (Ghostscript)
├── downsample-folder.bat    # Downsample folder tree
├── clean_pycache.bat        # Remove Python cache files
├── .gitignore
├── README.md
├── package-lock.json
│
├── python/                  # Python 3.13 runtime + libraries
│   ├── python.exe
│   ├── Lib\site-packages\
│   │   ├── ocrmypdf/        # OCRmyPDF
│   │   ├── pypdfium2/       # PDFium bindings
│   │   ├── pydantic/        # Data validation
│   │   ├── rich/            # Terminal formatting
│   │   └── ...              # (30+ dependency packages)
│   └── Scripts\
│       └── ocrmypdf.exe     # OCRmyPDF entry point
│
├── tesseract/               # Tesseract OCR 5
│   ├── tesseract.exe
│   └── tessdata\
│       ├── eng.traineddata  # English language model
│       └── osd.traineddata  # Orientation & script detection
│
└── ghostscript/             # Ghostscript
    ├── bin\
    │   ├── gswin64c.exe     # Console executable
    │   └── gswin64.exe      # GUI executable (unused)
    └── lib/                 # PostScript library files
```

---

## Vendored Component Versions

Check installed versions at any time:

```powershell
.\python\python.exe -m ocrmypdf --version
.\tesseract\tesseract.exe --version
.\ghostscript\bin\gswin64c.exe --version
```

---

## Workflows

### Typical OCR Workflow

1. **Downsample** large scanned PDFs first (optional but recommended for speed):
   ```bat
   downsample-pdf.bat C:\scans\huge_scan.pdf 150 80
   ```

2. **OCR** the downsampled file:
   ```bat
   ocr-pdf.bat C:\scans\low-quality\huge_scan_150dpi.pdf
   ```

3. The result is a compact, searchable PDF/A file.

### Bulk Processing Workflow

Process an entire folder of scanned PDFs in two steps:

```bat
:: Step 1: Downsample all PDFs to 150 DPI
downsample-folder.bat C:\scans 150 80

:: Step 2: OCR all downsampled PDFs
ocr-folder.bat C:\scans\low-quality
```

> **Tip:** Downsampling before OCR dramatically speeds up processing for
> high-DPI scans (300+ DPI) without noticeable OCR accuracy loss.

---

## Exit Codes

| Script | Exit Code 0 | Exit Code 1 |
|---|---|---|
| `ocr-pdf.bat` | OCR completed successfully | OCRmyPDF error or missing input |
| `ocr-folder.bat` | All files succeeded | One or more files failed |
| `downsample-pdf.bat` | Ghostscript completed successfully | Ghostscript error or invalid args |
| `downsample-folder.bat` | All files succeeded | One or more files failed |
| `clean_pycache.bat` | Always 0 | N/A |

All scripts that wrap external tools propagate the underlying tool's exit code.

---

## Troubleshooting

### "Python runtime not found"

The bundle expects `python\python.exe` relative to the script location. Ensure
the `python\` folder exists in the bundle root. The scripts automatically locate
themselves via `%~dp0`.

### "Tesseract couldn't find its language data"

The scripts set `TESSDATA_PREFIX` to `tesseract\tessdata\`. If you see language
errors, verify that `tesseract\tessdata\eng.traineddata` exists.

### "OCR is failing on a specific PDF"

Try these OCRmyPDF flags for difficult documents:

```bat
ocr-pdf.bat problem.pdf problem_ocr.pdf --force-ocr --deskew --rotate-pages --remove-background
```

### "Downsampling produced a larger file"

Ghostscript's pdfwrite device can sometimes increase file size for PDFs that are
already highly optimized. Try:
- Lowering JPEG quality further (e.g., `30`)
- Reducing the max DPI (e.g., `50`)
- Skipping files that are already small

### "Ghostscript executable not found"

The scripts expect `ghostscript\bin\gswin64c.exe`. Verify the `ghostscript\`
folder is present and contains the `bin\` subdirectory.

---

## Development

### Batch Script Conventions

- **All paths relative to `%~dp0`**: scripts resolve their own directory and
  build paths to bundled tools from there. Never hard-code absolute paths.
- **Heavily commented**: every line in the batch scripts carries an explanatory
  comment. When editing, maintain this convention.
- **Quote all filesystem paths**: use double-quotes around any variable that
  may contain spaces.
- **Forward extra arguments unchanged**: `ocr-pdf.bat` and `ocr-folder.bat`
  pass additional arguments directly to OCRmyPDF without interpretation.
- **Exit code propagation**: child scripts return the underlying tool's exit
  code. Folder scripts return non-zero if any child fails.
- **Avoid editing vendored content**: behavior changes belong in the root
  `.bat` wrappers, not in `python\`, `tesseract\`, or `ghostscript\`.

### Updating Dependencies

To update the Python packages:

```powershell
.\python\python.exe -m pip install --upgrade ocrmypdf
```

To update Tesseract or Ghostscript, download newer Windows binaries and replace
the respective folders. Ensure you copy all required DLLs.

### Cleaning Before Commit

Before committing, clean Python bytecode cache to reduce the bundle size:

```bat
clean_pycache.bat
```

### Testing

For a single-file smoke test after changing a wrapper script, supply explicit
input and output paths so default naming cannot overwrite a file:

```powershell
# OCR wrapper test
cmd /c ".\ocr-pdf.bat .\testPDF_JBIG2.pdf .\output\test_ocr.pdf"

# Downsampling wrapper test
cmd /c ".\downsample-pdf.bat .\testPDF_JBIG2.pdf 72 60 .\output\test_downsampled.pdf"
```

Expected outputs:
- OCR test: a searchable PDF/A file with embedded text layer
- Downsample test: a significantly smaller file with images resampled to max 72 DPI

---

## License & Credits

This project is a curated bundle of open-source tools, each under its own
license:

| Component | License |
|---|---|
| [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) | Apache 2.0 |
| [Ghostscript](https://www.ghostscript.com/) | AGPL |
| [Python](https://www.python.org/) | PSF License |
| [OCRmyPDF](https://ocrmypdf.readthedocs.io/) | MPL 2.0 |
| [pypdfium2](https://github.com/pypdfium2-team/pypdfium2) | Apache 2.0 / BSD 3-Clause |
| [pydantic](https://github.com/pydantic/pydantic) | MIT |
| [Rich](https://github.com/Textualize/rich) | MIT |

The batch scripts in this repository are provided as-is for convenience.