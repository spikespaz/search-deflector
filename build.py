#! py -3

from os.path import join
from shutil import copyfile
from os import remove, makedirs
from argparse import ArgumentParser
from subprocess import check_output

parser = ArgumentParser(description="Search Deflector Build Script")

parser.add_argument("-a", "-all", action="store_true", dest="all", help="build all binaries")
parser.add_argument("-s", "-setup", action="store_true", dest="setup", help="build setup binary")
parser.add_argument("-u", "-updater", action="store_true", dest="updater", help="build updater binary")
parser.add_argument("-d", "-deflector", action="store_true", dest="deflector", help="build deflector binary")
parser.add_argument("-i", "-installer", action="store_true", dest="installer", help="build installer executable")
parser.add_argument("-c", "-clean", action="store_true", dest="clean")
parser.add_argument(
    "-m",
    "-mode",
    choices=["r", "release", "s", "store", "d", "debug"],
    default="release",
    dest="mode",
    help="enable optimization or enable debug files")
parser.add_argument("-source", default="source", dest="source", metavar="<path>", help="path of the source code")
parser.add_argument("-libs", default="libs", dest="libs", metavar="<path>", help="path of the libraries")
parser.add_argument("-out", default="build", dest="out", metavar="<path>", help="path of the output binaries")

args = parser.parse_args()

if args.mode == "r":
    args.mode = "release"
elif args.mode == "s":
    args.mode = "store"
elif args.mode == "d":
    args.mode = "debug"

vars_path = join(args.out, "vars")

version_file = join(vars_path, "version.txt")
license_file = join(vars_path, "license.txt")
engines_file = join(vars_path, "engines.txt")

libcurl_lib = join(args.out, "libcurl.dll")

bins_path = join(args.out, "bin")

setup_bin = join(bins_path, "setup.exe")
updater_bin = join(bins_path, "updater.exe")
deflector_bin = join(bins_path, "deflector.exe")


def get_version():
    if args.mode == "debug":
        return "0.0.0"
    else:
        return check_output("git describe --tags --abbrev=0").decode().strip()


version = get_version()

_copied_files = False


def make_paths():
    print("Making binaries directory: " + bins_path)
    makedirs(bins_path, exist_ok=True)

    print("Making variables directory: " + vars_path)
    makedirs(vars_path, exist_ok=True)


def copy_files():
    global _copied_files

    if _copied_files:
        return

    # version.txt
    print("Creating version file: " + version_file)

    with open(version_file, "w") as out_file:
        out_file.write(get_version())

    # license.txt
    print("Creating license file: " + license_file)

    with open(license_file, "w") as out_file:
        with open("LICENSE") as in_file:
            out_file.write(in_file.read())

        with open(join(args.libs, "libcurl.txt")) as in_file:
            out_file.write("\n\n" + in_file.read())

    # engines.txt
    print("Copying engine templates file: " + engines_file)

    copyfile("engines.txt", engines_file)

    # libcurl.dll
    print("Copying libcurl library: " + libcurl_lib)

    copyfile(join("libs", "libcurl.dll"), libcurl_lib)

    _copied_files = True


def clean_files():
    # version.txt
    print("Removing version file: " + version_file)
    remove(version_file)

    # license.txt
    print("Removing license file: " + license_file)
    remove(version_file)

    # engines.txt
    print("Removing engine templates file: " + engines_file)
    remove(engines_file)


def build_setup():
    print("Compiling setup binary: " + setup_bin)

    command = [
        "ldc2", "\"" + join(args.source, "setup.d") + "\"", "-I", "\"" + args.source + "\"", "-J",
        "\"" + vars_path + "\"", "-of", "\"" + setup_bin + "\"", "-m32"
    ]

    if args.mode != "debug":
        command.extend(["-O3", "-ffast-math"])
    else:
        command.append("-g")

    print("> " + " ".join(command))


make_paths()

if args.setup:
    copy_files()
    build_setup()
