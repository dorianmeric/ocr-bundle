# OCR Bundle instructions

## Project model

This repository is a portable Windows OCR/PDF-processing bundle, not a Python
application to build or install. The root batch files are the maintained
integration layer; `python\`, `tesseract\`, and `ghostscript\` are bundled
runtimes and vendor assets.

- `ocr-pdf.bat` resolves paths from `%~dp0`, adds the bundled Tesseract and
  Ghostscript directories to `PATH`, sets `TESSDATA_PREFIX`, and invokes
  `python\python.exe -m ocrmypdf`.
- The single-PDF OCR defaults are intentional: English OCR, forced OCR,
  deskewing, page rotation, unlimited Tesseract timeout, optimization level
  3, cleaning, JPEG PDF/A image compression, and PDF/A output. Extra
  `ocrmypdf` arguments are forwarded before the input/output paths.
- `ocr-folder.bat` recursively finds PDFs and delegates each one to
  `ocr-pdf.bat`, preserving a failure count and returning nonzero when any
  child fails.
- `downsample-pdf.bat` runs bundled `ghostscript\bin\gswin64c.exe` with
  `pdfwrite`, downsampling color, grayscale, and monochrome images to a
  maximum DPI. Without an explicit output, it creates a sibling
  `low-quality\` directory and names the file `<name>_<dpi>dpi.pdf`.
- `downsample-folder.bat` recursively delegates to `downsample-pdf.bat` and
  deliberately skips PDFs under any `low-quality` path segment to avoid
  reprocessing its generated files.

## Commands

Run commands from the repository root in `cmd.exe` or invoke the batch files
with `cmd /c` from PowerShell. There is no build step, linter, or automated
test suite in this bundle.

```bat
:: OCR one file; omit output to create <input>_ocr.pdf next to the source.
ocr-pdf.bat input.pdf [output.pdf] [ocrmypdf options]

:: OCR every PDF below a directory.
ocr-folder.bat input_folder [ocrmypdf options]

:: Downsample one file (defaults: 72 DPI, JPEG quality 60).
downsample-pdf.bat input.pdf [max_dpi] [jpeg_quality] [output.pdf]

:: Downsample every eligible PDF below a directory.
downsample-folder.bat input_folder [max_dpi] [jpeg_quality]
```

For a single-file smoke check after changing an OCR wrapper, supply explicit
input and output paths so the default output naming cannot overwrite a file:

```powershell
cmd /c ".\ocr-pdf.bat C:\path\to\input.pdf C:\path\to\output.pdf"
```

For a downsampling-wrapper change, use:

```powershell
cmd /c ".\downsample-pdf.bat C:\path\to\input.pdf 72 60 C:\path\to\output.pdf"
```

Both commands return the underlying tool's exit code. The bundled runtime
versions can be checked with:

```powershell
.\python\python.exe -m ocrmypdf --version
.\tesseract\tesseract.exe --version
.\ghostscript\bin\gswin64c.exe --version
```

## Batch-script conventions

- Keep the bundle relocatable: derive all bundled executable paths from
  `%~dp0`; do not require system Python, Tesseract, or Ghostscript.
- Quote filesystem paths and forward extra OCRmyPDF options unchanged.
  `ocr-pdf.bat` treats the first non-option argument after the input as the
  output path; options must therefore follow the input or explicit output.
- Preserve the scripts' exit-code propagation and folder-level success/failure
  accounting. Invalid DPI must fail; JPEG quality is an integer from 0 to 100.
- Avoid editing bundled runtime contents unless deliberately updating the
  shipped dependency. Changes to behavior belong in the root `.bat` wrappers.
- `clean_pycache.bat` is maintenance-only: it deletes Python cache directories
  and bytecode recursively below its target (the bundle root by default).