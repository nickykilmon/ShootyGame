@echo off
title STOP FPS SERVER
echo Stopping game server and tunnel...
taskkill /IM Godot_v4.7.2-stable_win64_console.exe /F 2>nul
taskkill /IM Godot_v4.7.2-stable_win64.exe /F 2>nul
taskkill /IM cloudflared.exe /F 2>nul
echo Done.
timeout /t 2 >nul
