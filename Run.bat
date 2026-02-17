@echo off
:: WindowsXXP - Just double-click to run
:: Automatically requests Administrator privileges

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

powershell -ExecutionPolicy Bypass -File "%~dp0WindowsXXP.ps1"
pause
