@echo off
setlocal enabledelayedexpansion

set TRANS=lewa_v5\Russian\main
set WD=%~dp0\WORKDIR
set INP=%~dp0\_IN
set OUT=%~dp0\_OUT
set TOOLS=%~dp0\_tools
set LOG=%~n0.log
set APK=java -jar %TOOLS%\apktool_2.0.0b9.jar
set SIGN=java -jar %TOOLS%\signapk.jar %TOOLS%\cert\testkey.x509.pem %TOOLS%\cert\testkey.pk8
set ALIGN=%TOOLS%\zipalign.exe -f -v 4
set BAKSMALI=java -jar %TOOLS%\baksmali-2.0.3.jar -a 17

:: Make work dirs
rem if exist %WD% rmdir /s /q %WD%
if not exist %WD% mkdir %WD%
if not exist %OUT% mkdir %OUT%
if not exist %OUT%\app mkdir %OUT%\app
if not exist %OUT%\framework mkdir %OUT%\framework
if exist %LOG% del /q %LOG%

:: Install frameworks
for %%i in (%INP%\framework\*.apk) do %APK% install-framework %%i 2>> %LOG%

:: Translate apps
if "%1"=="" (
  for /d %%i in (%TRANS%\*.apk) do (
    set APP=%%~nxi
    if exist %INP%\app\!APP! call :translate_app %INP%\app\!APP!
    if exist %INP%\framework\!APP! call :translate_fwk %INP%\framework\!APP!
  )
) else (
  set APP=%1
  if exist %INP%\app\!APP! call :translate_app %INP%\app\!APP!
  if exist %INP%\framework\!APP! call :translate_fwk %INP%\framework\!APP!
)

exit 0

:translate_apk
  setlocal enabledelayedexpansion
  set APP=%~nx1
  echo Translating !APP! ...
  if exist %WD%\!APP! rmdir /s /q %WD%\!APP!
  if exist %WD%\_!APP! del /q %WD%\_!APP!
  %APK% decode --no-src %1 -o %WD%\!APP! 2>> %LOG%
  if exist %TRANS%\!APP!\smali %BAKSMALI% -x %~pn1.odex -d _IN\framework -o %WD%\!APP!\smali
  xcopy /sfy %TRANS%\!APP!\* %WD%\!APP! >> %LOG%
  if "!APP!"=="lewa-res.apk" call :lewa_res_hack
  %APK% build %WD%\!APP! -o %WD%\_!APP! 2>> %LOG%
rem -a %TOOLS%\aapt.exe
  endlocal
exit /b

:translate_app
  setlocal enabledelayedexpansion
  set APP=%~nx1
  call :translate_apk %1
  %SIGN% %WD%\_!APP! %WD%\__!APP! 2>> %LOG%
  %ALIGN% %WD%\__!APP! %OUT%\app\!APP! >> %LOG%
  del /q %WD%\_!APP! %WD%\__!APP!
  endlocal
exit /b

:translate_fwk
  setlocal enabledelayedexpansion
  set APP=%~nx1
  call :translate_apk %1
  xcopy /fy %1 %WD%\_!APP! >> %LOG%
  %TOOLS%\7z.exe u -tzip -mx=0 %WD%\_!APP! %CD%\%WD%\!APP!\build\apk\resources.arsc >> %LOG%
  %ALIGN% %WD%\_!APP! %OUT%\framework\!APP! >> %LOG%
  del /q %WD%\_!APP!
  endlocal
exit /b

:lewa_res_hack
  if exist %WD%\lewa-res.apk\apktool_new.yml del /q %WD%\lewa-res.apk\apktool_new.yml
  set PREV=""
  for /f "delims=" %%i in (%WD%\lewa-res.apk\apktool.yml) do (
    if "%%i"=="sdkInfo:" (
      if "!PREV!"=="  - 1" for %%j in (2 3 4 5 6 7 8) do echo   - %%j
    echo sdkInfo:
    ) else echo %%i
  set PREV=%%i
  ) >>%WD%\lewa-res.apk\apktool_new.yml
  move /y %WD%\lewa-res.apk\apktool_new.yml %WD%\lewa-res.apk\apktool.yml
exit /b
