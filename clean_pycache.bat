rem Disable command echo for cleaner output.
@echo off
rem Start a local environment scope and enable delayed expansion if needed.
setlocal enabledelayedexpansion

rem Capture the folder where this script is located.
set SCRIPT_DIR=%~dp0
rem If no argument was provided, use the script folder as target.
if "%~1"=="" (
    rem Default target path.
    set TARGET=%SCRIPT_DIR%
) else (
    rem Use user-supplied target path.
    set TARGET=%~1
)

rem Show which folder is being cleaned.
echo Cleaning Python cache from: %TARGET%
rem Print a blank separator line.
echo.

rem Delete all __pycache__ directories recursively under target.
for /d /r "%TARGET%" %%d in (__pycache__) do (
    rem Confirm directory still exists before removal.
    if exist "%%d" (
        rem Report directory removal.
        echo Removing: %%d
        rem Remove directory recursively and quietly.
        rd /s /q "%%d"
    )
)

rem Delete all .pyc and .pyo files recursively under target.
for /r "%TARGET%" %%f in (*.pyc *.pyo) do (
    rem Report file removal.
    echo Removing: %%f
    rem Delete file quietly.
    del /q "%%f"
)

rem Print a blank separator line.
echo.
rem Show completion summary.
echo Done! All __pycache__ folders and .pyc/.pyo files removed.
rem Keep window open so user can read the result.
pause
