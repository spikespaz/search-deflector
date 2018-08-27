#! /bin/sh

# release="0.0.0-$(git rev-parse --abbrev-ref HEAD)"
release="$(git describe --tags --abbrev=0)-$(git rev-parse --abbrev-ref HEAD)"
echo "Creating the build path: build/$release"
mkdir -p "build/$release"

if [[ "$#" -eq 0 ]]; then
    compile=("setup", "launcher", "updater", "deflector")
fi

if [[ "$@" = "setup" ]]; then
    echo "Compiling executable: build/$release/setup.exe"
    ldc2 "source/setup.d" "source/common.d" -of="build/$release/setup.exe" \
        -O3 -ffast-math -release -g

    echo "Adding icon to executable: build/$release/setup.exe"
    [ -e "build/$release/setup.exe" ] && \
        rcedit "build/$release/setup.exe" --set-icon "icons/icon.ico"
fi

if [[ "$@" = "launcher" ]]; then
    echo "Compiling executable: build/$release/launcher.exe"
    ldc2 "source/launcher.d" "source/common.d" -of="build/$release/launcher.exe" \
        -O3 -ffast-math -release -g

    echo "Adding icon to executable: build/$release/launcher.exe"
    [ -e "build/$release/launcher.exe" ] && \
        rcedit "build/$release/launcher.exe" --set-icon "icons/icon.ico"
fi

if [[ "$@" = "updater" ]]; then
    echo "Compiling executable: build/$release/updater.exe"
    ldc2 "source/updater.d" "source/common.d" -of="build/$release/updater.exe" \
        -O3 -ffast-math -release -g
fi

if [[ "$@" = "deflector" ]]; then
    echo "Compiling executable: build/$release/deflector.exe"
    ldc2 "source/deflector.d" "source/common.d" -of="build/$release/deflector.exe" \
        -O3 -ffast-math -release -g
fi

echo "Removing residual object files."
find "build/$release" -name "*.obj" -delete

echo "Copying engines file: build/$release/engines.txt"
cp "engines.txt" "build/$release"
echo "Copying libcurl library: build/$release/libcurl.dll"
cp $(which libcurl.dll) "build/$release"
