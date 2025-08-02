@echo off

if not exist "..\lib" mkdir ..\lib

cl -nologo -MT -TC -O2 -c miniz.c
lib -nologo miniz.obj -out:..\lib\miniz.lib

del *.obj
