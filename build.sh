#! /bin/sh
dmd deflector.d -O -release -inline -boundscheck=off
[ -e deflector.obj ] && rm deflector.obj
mv deflector.exe SearchDeflector.exe
