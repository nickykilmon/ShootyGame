@echo off
title Starting server...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0play.ps1"
echo.
echo (window closing in a moment - if you didn't see "SERVER IS LIVE" above, something went wrong)
pause
