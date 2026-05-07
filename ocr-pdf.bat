rem Disable command echo for cleaner output.
@echo off
rem Start a local environment scope for this script.
setlocal enabledelayedexpansion

rem Capture the folder where this script is located.
set "SCRIPT_DIR=%~dp0"
rem Define the bundled Python executable path.
set "PYTHON_EXE=%SCRIPT_DIR%python\python.exe"
rem Define the bundled Tesseract directory path.
set "TESSERACT_DIR=%SCRIPT_DIR%tesseract"
rem Define the bundled Ghostscript directory path.
set "GHOSTSCRIPT_DIR=%SCRIPT_DIR%ghostscript"
rem Define the bundled Ghostscript bin directory path.
set "GHOSTSCRIPT_BIN=%SCRIPT_DIR%ghostscript\bin"

rem Add bundled tools to PATH for this session and child processes.
set "PATH=%TESSERACT_DIR%;%GHOSTSCRIPT_DIR%;%GHOSTSCRIPT_BIN%;%PATH%"
rem Point Tesseract to bundled language data.
set "TESSDATA_PREFIX=%TESSERACT_DIR%\tessdata"

rem If no input file was provided, jump to usage help.
if "%~1"=="" goto :usage

rem Read the required input file argument.
set "INPUT=%~1"
rem Shift arguments so remaining values can be parsed.
shift

rem Initialize optional output file variable.
set "OUTPUT="
rem Initialize first remaining argument cache for output detection.
set "ARG1="
rem Parse optional output argument when next token is not an option flag.
if not "%~1"=="" (
    rem Cache normalized argument text for reliable prefix checks.
    set "ARG1=%~1"
    rem Ignore lone dash placeholder.
    if not "!ARG1!"=="-" (
        rem Treat non-dash-prefixed token as output file path.
        if not "!ARG1:~0,1!"=="-" (
            rem Store explicit output path.
            set "OUTPUT=%~1"
            rem Shift again so remaining tokens are extra ocrmypdf options.
            shift
        )
    )
)

rem If output was not specified, build default output beside input.
if "%OUTPUT%"=="" (
    rem Derive output as input filename plus _ocr suffix.
    for %%I in ("%INPUT%") do set "OUTPUT=%%~dpnI_ocr.pdf"
)

rem Initialize container for forwarded ocrmypdf options.
set "EXTRA_ARGS="
rem Label for argument collection loop.
:collect_args
rem Stop collecting when no arguments remain.
if "%~1"=="" goto :run
rem Append current argument with quotes for safe forwarding.
set "EXTRA_ARGS=!EXTRA_ARGS! "%~1""
rem Advance to next argument.
shift
rem Continue collecting arguments.
goto :collect_args

rem Main execution label.
:run
rem Print visual separator line.
echo ============================================================
rem Print script title.
echo OCR Bundle
rem Print visual separator line.
echo ============================================================
rem Show resolved input path.
echo Input : "%INPUT%"
rem Show resolved output path.
echo Output: "%OUTPUT%"
rem Show forwarded extra arguments when present.
if not "!EXTRA_ARGS!"=="" (
    rem Print additional ocrmypdf options.
    echo Extra :!EXTRA_ARGS!
) else (
    rem Print no-extra-options indicator.
    echo Extra : ^(none^)
)
rem Print a blank separator line.
echo.
rem Announce OCR start.
echo Starting OCR...
rem Print a blank separator line.
echo.

rem Validate bundled Python runtime exists before launch.
if not exist "%PYTHON_EXE%" (
    rem Report missing Python executable error.
    echo ERROR: Python runtime not found at "%PYTHON_EXE%"
    rem Keep window open so user can read the error.
    
    rem Return failure code.
    exit /b 1
)

rem Run OCRmyPDF with required and forwarded arguments.
if not "!EXTRA_ARGS!"=="" (
    rem Include extra options before positional input/output arguments.
    echo ----- COMMAND BEING RUN: "%PYTHON_EXE%" -m ocrmypdf --language eng --force-ocr --deskew --rotate-pages --tesseract-timeout=0 --optimize 3 --jpeg-quality 10 --clean !EXTRA_ARGS! "%INPUT%" "%OUTPUT%"
    "%PYTHON_EXE%" -m ocrmypdf --language eng --force-ocr --deskew --rotate-pages --tesseract-timeout=0 --optimize 3 --jpeg-quality 10 --clean !EXTRA_ARGS! "%INPUT%" "%OUTPUT%"
) else (
    rem Run with defaults when no additional options were provided.
    echo ----- COMMAND BEING RUN: "%PYTHON_EXE%" -m ocrmypdf --language eng --force-ocr --deskew --rotate-pages --tesseract-timeout=0 --optimize 3 --jpeg-quality 10 --clean "%INPUT%" "%OUTPUT%"
    "%PYTHON_EXE%" -m ocrmypdf --language eng --force-ocr --deskew --rotate-pages --tesseract-timeout=0 --optimize 3 --jpeg-quality 10 --clean "%INPUT%" "%OUTPUT%"
)
rem Capture OCRmyPDF exit code.
set "EXIT_CODE=%ERRORLEVEL%"

rem Print a blank separator line.
echo.
rem Print success path when exit code is zero.
if "%EXIT_CODE%"=="0" (
    rem Report successful completion.
    echo SUCCESS: OCR complete.
    rem Show output file path.
    echo Created: "%OUTPUT%"
) else (
    rem Report non-zero exit code failure.
    echo ERROR: OCR failed with exit code %EXIT_CODE%.
)

rem Keep window open so user can read final status.

rem Return underlying OCR command exit code.
exit /b %EXIT_CODE%

rem Usage/help label.
:usage
rem Print usage header.
echo Usage:
rem Print usage syntax.
echo   ocr.bat input.pdf [output.pdf] [ocrmypdf options]
rem Print a blank separator line.
echo.
rem Print examples header.
echo Examples:
rem Print example with default output.
echo   ocr.bat scan.pdf                       => output: scan_ocr.pdf
rem Print example with explicit output.
echo   ocr.bat scan.pdf scan_ocr.pdf
rem Print example forwarding a single option.
echo   ocr.bat scan.pdf --force-ocr           => output: scan_ocr.pdf
rem Print example forwarding multiple options.
echo   ocr.bat scan.pdf scan_ocr.pdf --force-ocr --deskew --pdfa-image-compression jpeg --rotate-pages --tesseract-timeout=0 --optimize 3 --jpeg-quality 10
rem Print a blank separator line.
echo.
echo --optimize 1 : Enables lossless optimizations, such as transcoding images to more efficient formats. Also compress other uncompressed objects in the PDF and enables the more efficient “object streams” within the PDF. (If --jbig2-lossy is issued, then lossy JBIG2 optimization is used. The decision to use lossy JBIG2 is separate from standard optimization settings.)
echo --optimize 2 : All of the above, and enables lossy optimizations and color quantization.
echo --optimize 3 : All of the above, and enables more aggressive optimizations and targets lower image quality.
rem Print notes header.
echo Notes:
rem Explain default output behavior.
echo   - If output.pdf is omitted, this script uses input_ocr.pdf
rem Explain extra options behavior.
echo   - Additional options are passed to ocrmypdf
rem Keep window open so user can read usage details.

rem Return failure code for incorrect usage.
exit /b 1

