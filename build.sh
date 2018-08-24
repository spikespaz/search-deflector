#! /bin/sh

# release="$(git describe --tags --abbrev=0)-$(git rev-parse --abbrev-ref HEAD)"
release="0.0.0-$(git rev-parse --abbrev-ref HEAD)"
mkdir -p "build/$release"

ldc2 "source/setup.d" "source/common.d" -of="build/$release/setup.exe" \
    -O3 -ffast-math -release
ldc2 "source/launcher.d" "source/common.d" -of="build/$release/launcher.exe" \
    -L/SUBSYSTEM:WINDOWS -O3 -ffast-math -release
ldc2 "source/updater.d" "source/common.d" -of="build/$release/updater.exe" \
    -O3 -ffast-math -release
ldc2 "source/deflector.d" "source/common.d" -of="build/$release/deflector.exe" \
    -O3 -ffast-math -release

find "build/$release" -name "*.obj" -delete

[ -e "build/$release/setup.exe" ] && \
    rcedit "build/$release/setup.exe" --set-icon "icons/icon.ico"
[ -e "build/$release/launcher.exe" ] && \
    rcedit "build/$release/launcher.exe" --set-icon "icons/icon.ico"

cp "engines.txt" "build/$release"
cp $(which libcurl.dll) "build/$release"
