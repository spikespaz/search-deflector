#! /bin/sh -e

# release="0.0.0-$(git rev-parse --abbrev-ref HEAD)"
release="$(git describe --tags --abbrev=0)-$(git rev-parse --abbrev-ref HEAD)"

echo "Creating the build path: build/$release"

mkdir -p "build/$release"

function setup {
    echo "Compiling executable: build/$release/setup.exe"
    ldc2 "source/setup.d" "source/common.d" -of="build/$release/setup.exe" \
        -O3 -ffast-math -release -g

    echo "Adding icon to executable: build/$release/setup.exe"
    [ -e "build/$release/setup.exe" ] && \
        rcedit "build/$release/setup.exe" --set-icon "icons/icon.ico"
}

function launcher {
    echo "Compiling executable: build/$release/launcher.exe"
    ldc2 "source/launcher.d" "source/common.d" -of="build/$release/launcher.exe" \
        -O3 -ffast-math -release -g

    echo "Adding icon to executable: build/$release/launcher.exe"
    [ -e "build/$release/launcher.exe" ] && \
        rcedit "build/$release/launcher.exe" --set-icon "icons/icon.ico"
}

function updater {
    echo "Compiling executable: build/$release/updater.exe"
    ldc2 "source/updater.d" "source/common.d" -of="build/$release/updater.exe" \
        -O3 -ffast-math -release -g
}

function deflector {
    echo "Compiling executable: build/$release/deflector.exe"
    ldc2 "source/deflector.d" "source/common.d" -of="build/$release/deflector.exe" \
        -O3 -ffast-math -release -g
}

function clean {
    echo "Removing debug files."
    find "build/$release" -name "*.pdb" -delete
}

if [ "$#" -eq 0 ]; then
    setup
    launcher
    updater
    deflector
else
    while [ "$#" -gt 0 ]; do
    param="$1"

    case $param in
        s|setup)
            setup
            shift
        ;;
        l|launcher)
            launcher
            shift
        ;;
        u|updater)
            updater
            shift
        ;;
        d|deflector)
            deflector
            shift
        ;;
        a|all)
            setup
            launcher
            updater
            deflector
            shift
        ;;
        c|clean)
            clean
            shift
    esac
    done
fi

echo "Removing residual object files."
find "build/$release" -name "*.obj" -delete

echo "Copying engines file: build/$release/engines.txt"
cp "engines.txt" "build/$release"
echo "Copying libcurl library: build/$release/libcurl.dll"
cp "libs/libcurl.dll" "build/$release"
echo "Copying license files: build/$release/LICENSE"
cp "LICENSE" "build/$release"
echo -e "\nhttps://github.com/spikespaz/search-deflector/blob/master/LICENSE \
    \n\n$(cat "libs/libcurl.txt")" >> "build/$release/LICENSE"
