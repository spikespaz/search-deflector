#! /bin/sh
mkdir -p build
ldc2 source/main.d source/setup.d source/deflect.d -of="build/SearchDeflector-x86.exe" -O3 -ffast-math -release
ldc2 source/main.d source/setup.d source/deflect.d -of="build/SearchDeflector-x64.exe" -m64 -O3 -ffast-math -release
cp $(which libcurl.dll) "build/libcurl.dll"
[ -e main.obj ] && rm main.obj
cd build
[ -e SearchDeflector-x86.exe ] &&
    rcedit SearchDeflector-x86.exe --set-icon ../icons/icon.ico
[ -e SearchDeflector-x64.exe ] &&
    rcedit SearchDeflector-x64.exe --set-icon ../icons/icon.ico
rm *.obj
