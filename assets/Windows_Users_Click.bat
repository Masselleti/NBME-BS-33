@echo off
chcp 65001 >nul 2>&1
title Medicine Academy - Starting Server...

echo.
echo ============================================================
echo.
echo         Medicine Academy - Question Bank
echo                   Starting Server...
echo.
echo ============================================================
echo.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Start-LocalServer.ps1"

echo.
echo ============================================================
echo Server has been stopped.
echo Press any key to exit...
pause >nul
