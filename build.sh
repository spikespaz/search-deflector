#! /bin/sh
dmd main.d deflect.d setup.d -O -release -inline -boundscheck=off
mkdir -p SearchDeflector
cp $(which libcurl.dll) SearchDeflector/libcurl.dll
[ -e main.obj ] && rm main.obj
[ -e main.exe ] &&
    rcedit main.exe --set-icon icons/icon.ico &&
    mv main.exe SearchDeflector/SearchDeflector.exe
