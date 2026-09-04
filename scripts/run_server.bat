@echo off
title FPS SERVER + TUNNEL
setlocal

REM --- edit these two paths if yours differ -------------------------------
set "GODOT=C:\Users\nrkil\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set "PROJECT=C:\Users\nrkil\Downloads\MultiplayerFPSTutorial-main\MultiplayerFPSTutorial-main"
REM ----------------------------------------------------------------------

echo Starting the game server in a new window...
start "FPS GAME SERVER" "%GODOT%" --headless --path "%PROJECT%" -- --server
timeout /t 2 >nul

echo.
echo ============================================================
echo   Cloudflare will print a line like:
echo       https://SOME-RANDOM-WORDS.trycloudflare.com
echo.
echo   1. Copy that URL.
echo   2. Open  server.txt  in the project folder.
echo   3. Replace the top line with:
echo          wss://SOME-RANDOM-WORDS.trycloudflare.com
echo      (wss://  not  https://)
echo   4. In GitHub Desktop: Commit to main, then Push.
echo.
echo   Players can join ~1-2 minutes later. Leave BOTH windows open.
echo ============================================================
echo.

cloudflared tunnel --url http://localhost:9999

echo.
echo Tunnel stopped. Run  stop_server.bat  to close the game server window too.
pause
