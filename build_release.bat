@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title TeoriX Release Builder

cls
echo ==============================================
echo           TeoriX Release Builder
echo ==============================================
echo.

echo [1/6] GitHub guncellemeleri aliniyor...
git pull
if errorlevel 1 goto :fail

echo.
echo [2/6] Flutter temizleniyor...
flutter clean
if errorlevel 1 goto :fail

echo.
echo [3/6] Paketler yukleniyor...
flutter pub get
if errorlevel 1 goto :fail

echo.
echo [4/6] Surum bilgisi okunuyor...
for /f "tokens=2" %%A in ('findstr /b /c:"version:" pubspec.yaml') do set FULLVER=%%A
for /f "tokens=1 delims=+" %%A in ("!FULLVER!") do set VERSION=%%A
if "!VERSION!"=="" set VERSION=unknown

echo Surum: !FULLVER!

echo.
echo [5/6] Release APK olusturuluyor...
flutter build apk --release
if errorlevel 1 goto :fail

echo.
echo [6/6] APK adlandiriliyor...
set OUTDIR=%~dp0release
if not exist "!OUTDIR!" mkdir "!OUTDIR!"
set SRC=%~dp0build\app\outputs\flutter-apk\app-release.apk
set DEST=!OUTDIR!\TeoriX-!VERSION!-Beta.apk

if not exist "!SRC!" (
  echo APK bulunamadi: !SRC!
  goto :fail
)

copy /Y "!SRC!" "!DEST!" >nul
if errorlevel 1 goto :fail

echo.
echo ==============================================
echo BUILD BASARILI
 echo APK: !DEST!
echo ==============================================
echo.
explorer "!OUTDIR!"
pause
exit /b 0

:fail
echo.
echo ==============================================
echo BUILD BASARISIZ
 echo Yukaridaki hatayi bana ekran goruntusu olarak at.
echo ==============================================
echo.
pause
exit /b 1
