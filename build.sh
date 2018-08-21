#! /bin/sh

release="$(git describe --tags --abbrev=0)-$(git rev-parse --abbrev-ref HEAD)"
mkdir -p "build/$release"

# ldc2 "source/setup.d" -of="build/$release/setup.exe" \
#     -L/SUBSYSTEM:WINDOWS -O3 -ffast-math -release
ldc2 "source/launcher.d" "source/common.d" -of="build/$release/launcher.exe" \
    -L/SUBSYSTEM:WINDOWS -O3 -ffast-math -release
# ldc2 "source/deflector.d" -of="build/$release/deflector.exe" \
#     -L/SUBSYSTEM:WINDOWS -O3 -ffast-math -release

find "build/$release" -name "*.obj" -delete

[ -e "build/$release/launcher.exe" ] && \
    rcedit "build/$release/launcher.exe" --set-icon "icons/icon.ico"

cp "build/$release/launcher.exe" "build/"
cp $(which libcurl.dll) "build/$release/libcurl.dll"
