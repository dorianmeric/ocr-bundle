rem Disable command echo for cleaner output.
@echo off
rem Start a local environment scope for this script.
setlocal enabledelayedexpansion
rem Capture the folder where this script is located.
set "SCRIPT_DIR=%~dp0"
rem Define the per-file OCR script path.
set "OCR_PDF_SCRIPT=%SCRIPT_DIR%ocr-pdf.bat"

rem Ensure required script exists before continuing.
if not exist "%OCR_PDF_SCRIPT%" (
    rem Report missing dependency.
    echo ERROR: Required script not found:
    echo   "%OCR_PDF_SCRIPT%"
    rem Keep window open so user can read error details.
    
    rem Return failure code.
    exit /b 1
)

rem Show usage when no parameters are provided.
if "%~1"=="" goto :usage

rem Default input folder to current directory.
set "INPUT_FOLDER=."
rem Initialize forwarded argument container.
set "EXTRA_ARGS="

rem Parse optional first argument as folder when it is not an option.
if not "%~1"=="" (
    rem Treat dash-prefixed values as options for the child script.
    if not "%~1:~0,1%"=="-" (
        rem Use first argument as input folder.
        set "INPUT_FOLDER=%~1"
        rem Shift so remaining values are extra options.
        shift
    )
)

rem Collect remaining arguments to forward to ocr-pdf.bat.
:collect_args
if "%~1"=="" goto :validate_input_folder
set "EXTRA_ARGS=!EXTRA_ARGS! "%~1""
shift
goto :collect_args

:validate_input_folder
rem Ensure input folder exists before scanning.
if not exist "%INPUT_FOLDER%" (
    rem Report missing folder.
    echo ERROR: Input folder not found:
    echo   "%INPUT_FOLDER%"
    rem Return failure code.
    exit /b 1
)

rem Initialize counters for a summary report.
set /a "FOUND_COUNT=0"
set /a "SUCCESS_COUNT=0"
set /a "FAIL_COUNT=0"

rem Recursively iterate over every PDF in the selected folder and subfolders.
for /r "%INPUT_FOLDER%" %%f in (*.pdf) do (
    rem Track discovered files.
    set /a "FOUND_COUNT+=1"
    rem Show the file currently being processed.
    echo ------------------------------------------------------------
    echo Processing: "%%f"
    rem Call per-file OCR script and forward additional options.
    if not "!EXTRA_ARGS!"=="" (
        call "%OCR_PDF_SCRIPT%" "%%f" !EXTRA_ARGS!
    ) else (
        call "%OCR_PDF_SCRIPT%" "%%f"
    )
    rem Track success/failure based on child script exit code.
    if errorlevel 1 (
        set /a "FAIL_COUNT+=1"
        echo Result: FAILED
    ) else (
        set /a "SUCCESS_COUNT+=1"
        echo Result: OK
    )
)

rem Print no-files message when no PDFs were discovered.
if "%FOUND_COUNT%"=="0" (
    echo No PDF files were found under "%INPUT_FOLDER%".
    
    exit /b 0
)

rem Show completion summary.
echo.
echo ============================================================
echo Summary
echo ============================================================
echo PDFs Found : %FOUND_COUNT%
echo Succeeded  : %SUCCESS_COUNT%
echo Failed     : %FAIL_COUNT%

rem Return failure if any file failed.
if %FAIL_COUNT% GTR 0 (
    echo One or more files failed.
    
    exit /b 1
)

rem Show completion message.
echo All done!
rem Keep window open so user can read the result.

exit /b 0

rem Usage/help label.
:usage
echo Usage:
echo   ocr-folder.bat input_folder [ocrmypdf options]
echo.
echo Examples:
echo   ocr-folder.bat .
echo   ocr-folder.bat C:\docs\pdfs
echo   ocr-folder.bat C:\docs\pdfs --force-ocr
echo   ocr-folder.bat C:\docs\pdfs --force-ocr --deskew
echo.
echo Notes:
echo   - Processes all PDF files recursively in input_folder
echo   - Any extra options are forwarded to ocr-pdf.bat for each file
echo   - To OCR the current folder tree, use: ocr-folder.bat .
exit /b 1



