#! py -3

from argparse import ArgumentParser

PARSER = ArgumentParser(description="Search Deflector Build Script")
ARGUMENTS = {
    "all": {
        "flags": ("-a", "-all"),
        "action": "store_true",
        "help": "build setup, updater, and deflector binaries"
    },
    "setup": {
        "flags": ("-s", "-setup"),
        "action": "store_true",
        "help": "build setup binary"
    },
    "updater": {
        "flags": ("-u", "-updater"),
        "action": "store_true",
        "help": "build updater binary"
    },
    "deflector": {
        "flags": ("-d", "-deflector"),
        "action": "store_true",
        "help": "build deflector binary"
    },
    "installer": {
        "flags": ("-i", "-installer"),
        "action": "store_true",
        "help": "build installer executable"
    },
    "clean": {
        "flags": ("-c", "-clean"),
        "action": "store_true",
        "help": "remove object and debug files"
    },
    "copy": {
        "flags": ("-cp", "-copy"),
        "action": "store_true",
        "help": "copy libraries and imports"
    },
    "mode": {
        "flags": ("-m", "-mode"),
        "choices": ("r", "release", "s", "store", "d", "debug"),
        "default": "debug",
        "help": "build classic installer, store edition, or debug mode"
    },
    "source": {
        "flags": "-source",
        "default": "source",
        "metavar": "<path>",
        "help": "path of the source code"
    },
    "libs": {
        "flags": "-libs",
        "default": "libs",
        "metavar": "<path>",
        "help": "path of the libraries"
    },
    "out": {
        "flags": "-out",
        "default": "build",
        "metavar": "<path>",
        "help": "path of the output binaries"
    },
    "verbose": {
        "flags": ("-v", "-verbose"),
        "action": "store_true",
        "help": "show log output"
    }
}


def assemble_args(parser, arguments):
    for dest, kwargs in arguments.items():
        flags = kwargs["flags"]
        kwargs.pop("flags", None)

        if isinstance(flags, str):
            parser.add_argument(flags, dest=dest, **kwargs)
        else:
            parser.add_argument(*flags, dest=dest, **kwargs)


def reform_args(args):
    if args.mode == "r":
        args.mode = "release"
    elif args.mode == "s":
        args.mode = "store"
    elif args.mode == "d":
        args.mode = "debug"

    if args.mode == "debug":
        args.installer = False
        args.clean = False
    elif args.mode in ("release", "store"):
        args.all = True
        args.installer = True
        args.clean = True

    if args.all:
        args.setup = True
        args.updater = True
        args.deflector = True

    return args


def copy_files(libs, out):
    pass


def clean_files(out):
    from glob import glob
    from os import remove
    from os.path import join

    for file in glob(join(out, "*.pdb")):
        print("Removing debug file: " + join(out, file))
        remove(file)

    for file in glob(join(out, "*.obj")):
        print("Removing object file: " + join(out, file))
        remove(file)


def compile_file(src_file, src_path, vars_path, out_file, debug=True):
    from subprocess import call

    command = ["ldc2", src_file, "-i", src_path, "-J", vars_path, "-of", out_file, "-m32"]

    if debug:
        command.append("-g")
    else:
        command.extend(["-O3", "-ffast-math", "-release"])

    print(">", *command)

    call(command)


def build_installer(out, version):
    pass


if __name__ == "__main__":
    from os import makedirs
    from os.path import join
    from shutil import rmtree, copyfile
    from subprocess import check_output

    assemble_args(PARSER, ARGUMENTS)

    ARGS = reform_args(PARSER.parse_args())

    BIN_PATH = join(ARGS.out, "bin")
    VARS_PATH = join(ARGS.out, "vars")
    DIST_PATH = join(ARGS.out, "dist")

    VERSION_STR = check_output("git describe --tags --abrev=0").strip()

    if not ARGS.verbose:
        print = lambda *_, **__: None

    if ARGS.mode in ("release", "store"):
        print("Removing build path: " + ARGS.out)
        rmtree(ARGS.out, ignore_errors=True)

    if ARGS.setup or ARGS.updater or ARGS.deflector or ARGS.installer:
        print("Making binaries path: " + BIN_PATH)
        makedirs(BIN_PATH, exist_ok=True)

        print("Making variables path: " + VARS_PATH)
        makedirs(VARS_PATH, exist_ok=True)

        version_file = join(ARGS.libs, "version.txt")

        print("Creating version file: " + version_file)
        with open(version_file, "w") as out_file:
            out_file.write(VERSION_STR)

        libcurl_lib = join(BIN_PATH, "libcurl.dll")

        print("Copying libcurl library: " + libcurl_lib)
        copyfile(join(ARGS.libs, "libcurl.dll"), libcurl_lib)

    if ARGS.setup:
        engines_file = join(VARS_PATH, "engines.txt")

        print("Copying engine templates file: " + engines_file)
        copyfile("engines.txt", engines_file)

        setup_bin = join(BIN_PATH, "setup.exe")

        print("Building setup binary: " + setup_bin)
        compile_file(join(ARGS.source, "setup.d"), ARGS.source, VARS_PATH, ARGS.out, ARGS.mode == "debug")

    if ARGS.updater:
        build_updater(ARGS.source, ARGS.libs, ARGS.out)

    if ARGS.deflector:
        build_deflector(ARGS.source, ARGS.libs, ARGS.out)

    if ARGS.installer:
        license_file = join(BIN_PATH, "license.txt")

        print("Creating license file: " + license_file)
        with open(license_file, "w") as out_file:
            with open("LICENSE") as in_file:
                out_file.write(in_file.read())

            out_file.write("\n\n")

            with open(join(ARGS.libs, "libcurl.txt")) as in_file:
                out_file.write(in_file.read())

        print("Making distribution path: " + DIST_PATH)
        makedirs(DIST_PATH, exist_ok=True)

        build_installer(ARGS.out, VERSION_STR)

    if ARGS.copy:
        copy_files(ARGS.libs, ARGS.out)

    if ARGS.clean:
        clean_files(BIN_PATH)
