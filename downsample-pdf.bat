rem Disable command echo for cleaner output.
@echo off
rem Start a local environment scope for this script.
setlocal

rem Capture the folder where this script is located.
set "SCRIPT_DIR=%~dp0"
rem Define bundled Ghostscript root directory.
set "GS_DIR=%SCRIPT_DIR%ghostscript"
rem Define bundled Ghostscript binary directory.
set "GS_BIN=%GS_DIR%\bin"
rem Define Ghostscript console executable path.
set "GS_EXE=%GS_BIN%\gswin64c.exe"

rem Add bundled Ghostscript paths to PATH for this session and child processes.
set "PATH=%GS_DIR%;%GS_BIN%;%PATH%"

rem If no input file was provided, jump to usage help.
if "%~1"=="" goto :usage

rem Read required input PDF path.
set "INPUT=%~1"
rem Set default maximum DPI.
set "MAX_DPI=72"
rem Set default JPEG quality percentage.
set "JPEG_QUALITY=60"
rem Initialize optional output path.
set "OUTPUT="

rem Override max DPI if second argument is provided.
if not "%~2"=="" set "MAX_DPI=%~2"

rem Parse third argument as JPEG quality or output path.
if not "%~3"=="" (
    rem Check if third argument is an integer.
    echo(%~3| findstr /r "^[0-9][0-9]*$" >nul
    rem When numeric, treat third argument as JPEG quality.
    if not errorlevel 1 (
        rem Store JPEG quality from third argument.
        set "JPEG_QUALITY=%~3"
        rem Parse optional fourth argument as output path.
        if not "%~4"=="" set "OUTPUT=%~4"
    ) else (
        rem Store output path from third argument when quality is omitted.
        set "OUTPUT=%~3"
    )
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

rem Map JPEG quality percentage directly to Ghostscript JPEGQ (0-100).
set "JPEGQ=%JPEG_QUALITY%"

rem Build default output filename when none is specified.
if "%OUTPUT%"=="" (
    rem Create low-quality subfolder beside input file when it does not exist.
    for %%I in ("%INPUT%") do if not exist "%%~dpIlow-quality" mkdir "%%~dpIlow-quality"
    rem Derive output filename in low-quality folder with _<dpi>dpi suffix.
    for %%I in ("%INPUT%") do set "OUTPUT=%%~dpIlow-quality\%%~nI_%MAX_DPI%dpi.pdf"
)

rem Ensure bundled Ghostscript executable exists before running.
if not exist "%GS_EXE%" (
    rem Report missing Ghostscript executable.
    echo ERROR: Ghostscript executable not found at:
    rem Print expected executable path.
    echo   "%GS_EXE%"
    rem Keep window open so user can read error details.
    
    rem Return failure code.
    exit /b 1
)

rem Ensure input file exists before running Ghostscript.
if not exist "%INPUT%" (
    rem Report missing input file.
    echo ERROR: Input file not found:
    rem Print missing input path.
    echo   "%INPUT%"
    rem Keep window open so user can read error details.
    
    rem Return failure code.
    exit /b 1
)

rem Print visual separator line.
echo ============================================================
rem Print script title.
echo PDF Max-DPI Downsampler
rem Print visual separator line.
echo ============================================================
rem Show resolved input path.
echo Input   : "%INPUT%"
rem Show requested max DPI.
echo Max DPI : %MAX_DPI%
rem Show requested JPEG quality percentage.
echo JPEG %%  : %JPEG_QUALITY%
rem Show resolved output path.
echo Output  : "%OUTPUT%"
rem Print a blank separator line.
echo.
rem Announce processing start.
echo Processing PDF with Ghostscript...
rem Print a blank separator line.
echo.

rem Initialize Ghostscript argument list.
set "GS_ARGS="
rem Enable safer mode.
set "GS_ARGS=%GS_ARGS% -dSAFER"
rem Process all pages and then exit.
set "GS_ARGS=%GS_ARGS% -dBATCH"
rem Do not pause between pages.
set "GS_ARGS=%GS_ARGS% -dNOPAUSE"
rem Select PDF writer output device.
set "GS_ARGS=%GS_ARGS% -sDEVICE=pdfwrite"
rem Set target PDF compatibility level.
set "GS_ARGS=%GS_ARGS% -dCompatibilityLevel=1.6"
rem Reuse duplicate image streams when possible.
set "GS_ARGS=%GS_ARGS% -dDetectDuplicateImages=true"
rem Compress embedded fonts.
set "GS_ARGS=%GS_ARGS% -dCompressFonts=true"
rem Subset fonts to used glyphs.
set "GS_ARGS=%GS_ARGS% -dSubsetFonts=true"
rem Enable color image downsampling.
set "GS_ARGS=%GS_ARGS% -dDownsampleColorImages=true"
rem Use bicubic downsampling for color images.
set "GS_ARGS=%GS_ARGS% -dColorImageDownsampleType=/Bicubic"
rem Set color image max resolution.
set "GS_ARGS=%GS_ARGS% -dColorImageResolution=%MAX_DPI%"
rem Downsample color only when above target resolution.
set "GS_ARGS=%GS_ARGS% -dColorImageDownsampleThreshold=1.0"
rem Enable grayscale image downsampling.
set "GS_ARGS=%GS_ARGS% -dDownsampleGrayImages=true"
rem Use bicubic downsampling for grayscale images.
set "GS_ARGS=%GS_ARGS% -dGrayImageDownsampleType=/Bicubic"
rem Set grayscale image max resolution.
set "GS_ARGS=%GS_ARGS% -dGrayImageResolution=%MAX_DPI%"
rem Downsample grayscale only when above target resolution.
set "GS_ARGS=%GS_ARGS% -dGrayImageDownsampleThreshold=1.0"
rem Enable monochrome image downsampling.
set "GS_ARGS=%GS_ARGS% -dDownsampleMonoImages=true"
rem Use subsample downsampling for monochrome images.
set "GS_ARGS=%GS_ARGS% -dMonoImageDownsampleType=/Subsample"
rem Set monochrome image max resolution.
set "GS_ARGS=%GS_ARGS% -dMonoImageResolution=%MAX_DPI%"
rem Downsample monochrome only when above target resolution.
set "GS_ARGS=%GS_ARGS% -dMonoImageDownsampleThreshold=1.0"
rem Force JPEG compression for color images.
set "GS_ARGS=%GS_ARGS% -dAutoFilterColorImages=false -dColorImageFilter=/DCTEncode"
rem Force JPEG compression for grayscale images.
set "GS_ARGS=%GS_ARGS% -dAutoFilterGrayImages=false -dGrayImageFilter=/DCTEncode"
rem Set JPEG quality level used by DCT encoding.
set "GS_ARGS=%GS_ARGS% -dJPEGQ=%JPEGQ%"
rem Run Ghostscript with the assembled arguments.
"%GS_EXE%" %GS_ARGS% -sOutputFile="%OUTPUT%" "%INPUT%"

rem Capture Ghostscript exit code.
set "EXIT_CODE=%ERRORLEVEL%"
rem Print a blank separator line.
echo.
rem Report success when exit code is zero.
if "%EXIT_CODE%"=="0" (
    rem Print success message.
    echo SUCCESS: Created downsampled PDF.
    rem Print output file path.
    echo   "%OUTPUT%"
    rem Print input/output size statistics and reduction percentage.
    call :print_size_stats "%INPUT%" "%OUTPUT%"
) else (
    rem Print failure message with exit code.
    echo ERROR: Ghostscript failed with exit code %EXIT_CODE%.
)

rem Keep window open so user can read final status.

rem Return Ghostscript exit code.
exit /b %EXIT_CODE%

rem Usage/help label.
:usage
rem Print usage header.
echo Usage:
rem Print usage syntax.
echo   downsample-pdf.bat input.pdf [max_dpi] [jpeg_quality] [output.pdf]
echo   downsample-pdf.bat input.pdf [max_dpi] [output.pdf]
rem Print a blank separator line.
echo.
rem Print examples header.
echo Examples:
rem Print example using default max DPI.
echo   downsample-pdf.bat input.pdf     => output: .\low-quality\input_72dpi.pdf
rem Print example using custom max DPI.
echo   downsample-pdf.bat input.pdf 72
rem Print example using custom max DPI and JPEG quality.
echo   downsample-pdf.bat input.pdf 72 60
rem Print example using custom max DPI and explicit output.
echo   downsample-pdf.bat input.pdf 72 output.pdf
rem Print example using all inputs.
echo   downsample-pdf.bat input.pdf 72 60 output.pdf
rem Print a blank separator line.
echo.
rem Print notes header.
echo Notes:
rem Explain default max DPI behavior.
echo   - Default max_dpi is 72
rem Explain when downsampling occurs.
echo   - Images above max_dpi are downsampled
rem Explain that lower/equal DPI images are preserved.
echo   - Images already at or below max_dpi are kept as-is
rem Explain default JPEG quality behavior.
echo   - Default jpeg_quality is 60
rem Explain JPEG quality range.
echo   - jpeg_quality must be 0 to 100 (100 is best quality)
rem Explain default output location.
echo   - Default output is written to a low-quality subfolder next to input
rem Keep window open so user can read usage details.

rem Return failure code for incorrect usage.
exit /b 1

rem Print file size statistics (MB with 2 decimals) and percentage reduction.
:print_size_stats
rem Read input and output file paths from subroutine arguments.
set "SIZE_INPUT=%~1"
set "SIZE_OUTPUT=%~2"
rem Print formatted size stats directly from PowerShell.
powershell -NoProfile -Command "$inPath='%SIZE_INPUT%'; $outPath='%SIZE_OUTPUT%'; $inBytes=(Get-Item -LiteralPath $inPath).Length; $outBytes=(Get-Item -LiteralPath $outPath).Length; $inMB=[math]::Round($inBytes / 1MB, 2); $outMB=[math]::Round($outBytes / 1MB, 2); if($inBytes -eq 0){$reduction=0}else{$reduction=[math]::Round((($inBytes - $outBytes) * 100.0) / $inBytes, 2)}; Write-Output ('Input Size : ' + $inMB.ToString('F2') + ' MB'); Write-Output ('Output Size: ' + $outMB.ToString('F2') + ' MB'); Write-Output ('Reduction : ' + $reduction.ToString('F2') + '%%')"
rem Return to caller.
goto :eof


