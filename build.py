#! py -3

from glob import glob
from os.path import join
from os import remove, makedirs
from shutil import copyfile, rmtree
from argparse import ArgumentParser
from subprocess import check_output, call

parser = ArgumentParser(description="Search Deflector Build Script")

parser.add_argument(
    "-a", "-all", action="store_true", dest="all", help="build all binaries")
parser.add_argument(
    "-s", "-setup", action="store_true", dest="setup", help="build setup binary")
parser.add_argument(
    "-u", "-updater", action="store_true", dest="updater", help="build updater binary")
parser.add_argument(
    "-d",
    "-deflector",
    action="store_true",
    dest="deflector",
    help="build deflector binary")
parser.add_argument(
    "-i",
    "-installer",
    action="store_true",
    dest="installer",
    help="build installer executable")
parser.add_argument("-c", "-clean", action="store_true", dest="clean")
parser.add_argument(
    "-m",
    "-mode",
    choices=["r", "release", "s", "store", "d", "debug"],
    default="release",
    dest="mode",
    help="build classic installer, store edition, or debug mode")
parser.add_argument(
    "-source",
    default="source",
    dest="source",
    metavar="<path>",
    help="path of the source code")
parser.add_argument(
    "-libs", default="libs", dest="libs", metavar="<path>", help="path of the libraries")
parser.add_argument(
    "-out",
    default="build",
    dest="out",
    metavar="<path>",
    help="path of the output binaries")

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

bins_path = join(args.out, "bin")

setup_bin = join(bins_path, "setup.exe")
updater_bin = join(bins_path, "updater.exe")
deflector_bin = join(bins_path, "deflector.exe")
libcurl_lib = join(bins_path, "libcurl.dll")


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


def build_executable(*source_files, out_file):
    print("Compiling binary: " + out_file)

    command = [
        "ldc2", *(join(args.source, file) for file in source_files), "-J", vars_path,
        "-of", out_file, "-m32"
    ]

    if args.mode != "debug":
        command.extend(["-O3", "-ffast-math"])
    else:
        command.append("-g")

    print(">", *command)

    call(command)


def main():
    if args.mode != "debug":
        rmtree(args.out)

    make_paths()

    if args.setup:
        copy_files()
        build_executable("setup.d", "common.d", out_file=setup_bin)

    if args.updater:
        copy_files()
        build_executable("updater.d", "common.d", out_file=updater_bin)

    if args.deflector:
        copy_files()
        build_executable("deflector.d", "common.d", out_file=deflector_bin)

    if args.clean or args.mode != "debug":
        for file in glob(join(bins_path, "*.obj")):
            print("Removing object file: " + file)
            remove(file)

        for file in glob(join(bins_path, "*.obj")):
            print("Removing debug file: " + file)
            remove(file)


main()
