#! /bin/sh
dmd main.d deflect.d setup.d -O -release -inline -boundscheck=off
[ -e main.obj ] && rm main.obj
rcedit main.exe --set-icon icons/icon.ico
mv main.exe SearchDeflector.exe
