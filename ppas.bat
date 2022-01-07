@echo off
SET THEFILE=Automodeling.exe
echo Linking %THEFILE%
D:\lazarus\fpc\2.2.2\bin\i386-win32\ld.exe -b pe-i386 -m i386pe  --gc-sections    --entry=_mainCRTStartup    -o Automodeling.exe link.res
if errorlevel 1 goto linkend
D:\lazarus\fpc\2.2.2\bin\i386-win32\postw32.exe --subsystem console --input Automodeling.exe --stack 262144
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occured while assembling %THEFILE%
goto end
:linkend
echo An error occured while linking %THEFILE%
:end
