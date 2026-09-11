@echo off
setlocal
set GRADLE_VERSION=8.14
set DIST_ROOT=%~dp0.gradle-local
set GRADLE_HOME=%DIST_ROOT%\gradle-%GRADLE_VERSION%
if not exist "%GRADLE_HOME%\bin\gradle.bat" (
  echo Descargando Gradle %GRADLE_VERSION% por primera vez...
  if not exist "%DIST_ROOT%" mkdir "%DIST_ROOT%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $zip=Join-Path $env:TEMP 'gradle-8.14-bin.zip'; Invoke-WebRequest 'https://services.gradle.org/distributions/gradle-8.14-bin.zip' -OutFile $zip; Expand-Archive -Path $zip -DestinationPath '%DIST_ROOT%' -Force"
  if errorlevel 1 exit /b 1
)
call "%GRADLE_HOME%\bin\gradle.bat" %*
