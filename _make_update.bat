@echo off

set UPD=g2l_lewa_v5_rus
set SIGN=java -jar _tools\signapk.jar _tools\cert\testkey.x509.pem _tools\cert\testkey.pk8

if exist %UPD% rmdir /q /s %UPD%
if exist %UPD%.zip del /q %UPD%.zip
if exist %UPD%_.zip del /q %UPD%_.zip
mkdir %UPD%
xcopy /efyi META-INF %UPD%\META-INF
xcopy /efyi _OUT\* %UPD%\system
_tools\7z.exe a -tzip %UPD%_.zip %CD%\%UPD%\*
%SIGN% %UPD%_.zip %UPD%.zip
del /q %UPD%_.zip
rmdir /q /s %UPD%