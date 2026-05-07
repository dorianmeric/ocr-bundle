rem Disable command echo for cleaner output.
@echo off
rem Start a local environment scope for this script.
setlocal enabledelayedexpansion

rem Capture the folder where this script is located.
set "SCRIPT_DIR=%~dp0"
rem Define the single-file downsampling script path.
set "DOWNSAMPLE_SCRIPT=%SCRIPT_DIR%downsample-pdf.bat"

rem Ensure required script exists before continuing.
if not exist "%DOWNSAMPLE_SCRIPT%" (
    rem Report missing dependency.
    echo ERROR: Required script not found:
    echo   "%DOWNSAMPLE_SCRIPT%"
    rem Keep window open so user can read error details.
    
    rem Return failure code.
    exit /b 1
)

rem If no input folder was provided, jump to usage help.
if "%~1"=="" goto :usage

rem Read required input folder.
set "INPUT_FOLDER=%~1"
rem Set default max DPI passed to child script.
set "MAX_DPI=72"
rem Set default JPEG quality passed to child script.
set "JPEG_QUALITY=60"

rem Override max DPI when second argument is provided.
if not "%~2"=="" set "MAX_DPI=%~2"
rem Override JPEG quality when third argument is provided.
if not "%~3"=="" set "JPEG_QUALITY=%~3"

rem Ensure input folder exists.
if not exist "%INPUT_FOLDER%" (
    rem Report missing folder.
    echo ERROR: Input folder not found:
    echo   "%INPUT_FOLDER%"
    rem Keep window open so user can read error details.
    
    rem Return failure code.
    exit /b 1
)

rem Validate max DPI is a positive integer.
echo(%MAX_DPI%| findstr /r "^[1-9][0-9]*$" >nul
rem Handle invalid max DPI values.
if errorlevel 1 (
    rem Report validation error.
    echo ERROR: max_dpi must be a positive integer. Received: "%MAX_DPI%"
    rem Show usage after validation failure.
    goto :usage
)

rem Validate JPEG quality is an integer from 0 to 100.
echo(%JPEG_QUALITY%| findstr /r "^[0-9][0-9]*$" >nul
rem Handle non-integer JPEG quality values.
if errorlevel 1 (
    rem Report validation error for JPEG quality type.
    echo ERROR: jpeg_quality must be an integer from 0 to 100. Received: "%JPEG_QUALITY%"
    rem Show usage after validation failure.
    goto :usage
)

rem Reject JPEG quality below 0.
if %JPEG_QUALITY% LSS 0 (
    rem Report range error for low JPEG quality.
    echo ERROR: jpeg_quality must be between 0 and 100. Received: "%JPEG_QUALITY%"
    rem Show usage after validation failure.
    goto :usage
)

rem Reject JPEG quality above 100.
if %JPEG_QUALITY% GTR 100 (
    rem Report range error for high JPEG quality.
    echo ERROR: jpeg_quality must be between 0 and 100. Received: "%JPEG_QUALITY%"
    rem Show usage after validation failure.
    goto :usage
)

rem Print run header.
echo ============================================================
echo Folder PDF Downsampler
echo ============================================================
echo Input Folder : "%INPUT_FOLDER%"
echo Max DPI      : %MAX_DPI%
echo JPEG Quality : %JPEG_QUALITY%
echo.

rem Initialize summary counters.
set /a "FOUND_COUNT=0"
set /a "SUCCESS_COUNT=0"
set /a "FAIL_COUNT=0"
set /a "SKIPPED_COUNT=0"

rem Recursively process every PDF in the input folder.
for /r "%INPUT_FOLDER%" %%F in (*.pdf) do (
    rem Capture current file directory for skip detection.
    set "FILE_DIR=%%~dpF"
    rem Remove low-quality segment from a test copy of the path.
    set "LOWQ_TEST=!FILE_DIR:\low-quality\=!"
    rem Skip files whose directory path contains a low-quality segment.
    if /i not "!LOWQ_TEST!"=="!FILE_DIR!" (
        set /a "SKIPPED_COUNT+=1"
        echo ------------------------------------------------------------
        echo Skipping low-quality file: "%%F"
    ) else (
        rem Count discovered PDFs that are eligible for processing.
        set /a "FOUND_COUNT+=1"
        rem Print current file path.
        echo ------------------------------------------------------------
        echo Processing: "%%F"
        rem Call single-file script using default output logic (low-quality subfolder).
        call "%DOWNSAMPLE_SCRIPT%" "%%F" %MAX_DPI% %JPEG_QUALITY%
        rem Track success/failure based on child exit code.
        if errorlevel 1 (
            set /a "FAIL_COUNT+=1"
            echo Result: FAILED
        ) else (
            set /a "SUCCESS_COUNT+=1"
            echo Result: OK
        )
    )
)

rem Print summary when no PDFs were found.
if "%FOUND_COUNT%"=="0" (
    echo No PDF files were found under "%INPUT_FOLDER%".
    
    exit /b 0
)

rem Print final summary.
echo.
echo ============================================================
echo Summary
echo ============================================================
echo PDFs Found : %FOUND_COUNT%
echo Succeeded  : %SUCCESS_COUNT%
echo Failed     : %FAIL_COUNT%
echo Skipped    : %SKIPPED_COUNT%

rem Return non-zero when any file failed.
if %FAIL_COUNT% GTR 0 (
    echo One or more files failed.
    
    exit /b 1
)

rem Report overall success.
echo All files processed successfully.

exit /b 0

rem Usage/help label.
:usage
echo Usage:
echo   downsample-folder.bat input_folder [max_dpi] [jpeg_quality]
echo.
echo Examples:
echo   downsample-folder.bat .
echo   downsample-folder.bat C:\docs\pdfs 100
echo   downsample-folder.bat C:\docs\pdfs 100 60
echo.
echo Notes:
echo   - Processes all .pdf files recursively in input_folder
echo   - Skips any file inside a subfolder named low-quality
echo   - Delegates each file to downsample-pdf.bat
echo   - Default max_dpi is 72
echo   - Default jpeg_quality is 60

exit /b 1
