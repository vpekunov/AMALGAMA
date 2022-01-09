@echo off
d:\lazarus\fpc\3.0.2\bin\i386-win32\fpc -B -O3 -WC -Mobjfpc -FcUTF-8 %1.pas > %2
@cls