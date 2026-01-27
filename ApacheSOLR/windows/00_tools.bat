@echo off
title peviitor_core - tools installer
setlocal ENABLEDELAYEDEXPANSION

call :ASK "WSL" :WSL_YES
call :ASK "Docker Desktop" :DOCKER_YES
call :ASK "Visual Studio Code" :VSCODE_YES
call :ASK "GitHub Desktop" :GHDESK_YES
call :ASK "Comet Browser" :COMET_YES
call :ASK "Git (CLI)" :GIT_YES

echo.
echo All tools processed. Some installations require reboot or manual steps.
pause
goto :EOF

:: ---------- generic ask function ----------
:ASK
set "TOOL=%~1"
set "TARGET=%~2"

:ASK_LOOP
set "CHOICE="
set /p CHOICE=Do you want to install %TOOL% now? (Y/N) 
if /I "!CHOICE!"=="Y" goto %TARGET%
if /I "!CHOICE!"=="N" goto :EOF
echo Please answer Y or N.
goto ASK_LOOP

:: ---------- per‑tool actions ----------

:WSL_YES
echo Installing WSL (may require admin and reboot)...
wsl --install
echo WSL command finished. If prompted, reboot your PC.
goto :EOF

:DOCKER_YES
echo Opening Docker Desktop download page...
start "" "https://www.docker.com/products/docker-desktop/"
echo Download and install Docker Desktop from the opened page.
goto :EOF

:VSCODE_YES
echo Opening Visual Studio Code download page...
start "" "https://code.visualstudio.com/Download"
echo Download and install VS Code (System Installer, x64).
goto :EOF

:GHDESK_YES
echo Opening GitHub Desktop download page...
start "" "https://desktop.github.com/"
echo Download and install GitHub Desktop.
goto :EOF

:COMET_YES
echo Opening Comet Browser page...
start "" "https://www.perplexity.ai/comet"
echo Download and install Comet Browser from the opened page.
goto :EOF

:GIT_YES
echo Opening Git for Windows download page...
start "" "https://git-scm.com/download/win"
echo Download and install Git with default options.
goto :EOF
