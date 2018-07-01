#! /bin/sh
ldc2 main.d -m64 -i -O3 -ffast-math -release
mkdir -p SearchDeflector
cp $(which libcurl.dll) SearchDeflector/libcurl.dll
[ -e main.obj ] && rm main.obj
[ -e main.exe ] &&
    rcedit main.exe --set-icon icons/icon.ico &&
    mv main.exe SearchDeflector/SearchDeflector.exe
