@echo off
title Deploy to GitHub
echo ======================================================================
echo   1-CLICK GITHUB REPOSITORY DEPLOYMENT
echo ======================================================================
echo.
git init
git add .
git commit -m "feat: complete 4-member integrated smart overload and ANPR system"
git branch -M main
echo.
set /p REPO_URL="Enter your GitHub Repository URL (e.g. https://github.com/username/repo.git): "
if "%REPO_URL%"=="" (
    echo [!] No URL provided. Aborting.
    pause
    exit /b
)
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%
echo.
echo [*] Pushing all files to GitHub main branch...
git push -u origin main
echo.
echo [OK] Done! Visit your GitHub repository in your browser.
pause
