#! py -3

from os.path import join, dirname, basename, isfile
from subprocess import call, check_output
from argparse import ArgumentParser
from shutil import rmtree, copyfile
from os import remove, makedirs
from glob import glob

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
    "sources": {
        "flags": "-sources",
        "nargs": "*",
        "default": ("icons", "installer", "source", "libs"),
        "metavar": "<path>",
        "help": "paths of the source files"
    },
    "imports": {
        "flags": "-imports",
        "default": "source",
        "metavar": "<path>",
        "help": "path of modules imported by the source code"
    },
    "out": {
        "flags": "-out",
        "default": "build",
        "metavar": "<path>",
        "help": "path of the output files"
    },
    "verbose": {
        "flags": ("-v", "-verbose"),
        "action": "store_true",
        "help": "show log output"
    }
}

LOG_VERBOSE = False


def log_print(*args, **kwargs):
    if LOG_VERBOSE:
        print(*args, **kwargs)


def assemble_args(parser, arguments):
    for dest, kwargs in arguments.items():
        flags = kwargs.pop("flags")

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

    if not any((
            args.setup,
            args.updater,
            args.deflector,
            args.installer
    )):
        args.all = True

        if args.mode in ("release", "store"):
            args.installer = True
            args.clean = True

    if args.all:
        args.setup = True
        args.updater = True
        args.deflector = True

    if any((
            args.setup,
            args.updater,
            args.deflector,
            args.installer
    )):
        args.copy = True

    source_files = {}

    for directory in args.sources:
        for file in glob(join(directory, "*.*")):
            if isfile(file):
                source_files[basename(file)] = file

    args.sources = source_files

    return args


def get_version(debug=True):
    if debug:
        return "0.0.0"
    else:
        return check_output("git describe --tags --abbrev=0", shell=True).decode().strip()


def compile_file(src_file, vars_path, out_file, debug=True):
    command = ["ldc2", src_file, "-i", "-I", dirname(src_file), "-J", vars_path, "-of", out_file, "-m32"]

    if debug:
        command.append("-g")
    else:
        command.extend(["-O3", "-ffast-math", "-release"])

    log_print(">", *command)

    call(command)


def build_installer(src_file, out_path, version_str):
    log_print("Compiling installer: " + out_path)
    command = "iscc \"/O{}\" /Q \"/DAppVersion={}\" \"{}\"".format(out_path, version_str, src_file)

    log_print("> " + command)
    call(command)


def clean_files(out_path):
    for file in glob(join(out_path, "*.pdb")):
        log_print("Removing debug file: " + join(out_path, file))
        remove(file)

    for file in glob(join(out_path, "*.obj")):
        log_print("Removing object file: " + join(out_path, file))
        remove(file)


def copy_files(source, bin_path, vars_path, version_str):
    log_print("Making binaries path: " + bin_path)
    makedirs(bin_path, exist_ok=True)

    log_print("Making variables path: " + vars_path)
    makedirs(vars_path, exist_ok=True)

    version_file = join(vars_path, "version.txt")

    log_print("Creating version file: " + version_file)

    with open(version_file, "w") as out_file:
        out_file.write(version_str)

    engines_file = join(vars_path, "engines.txt")

    log_print("Copying engine templates file: " + engines_file)
    copyfile(source["engines.txt"], engines_file)

    issue_file = join(vars_path, "issue.txt")

    log_print("Copying issue template file: " + issue_file)
    copyfile(source["issue.txt"], issue_file)

    libcurl_lib = join(bin_path, "libcurl.dll")

    log_print("Copying libcurl library: " + libcurl_lib)
    copyfile(source["libcurl.dll"], libcurl_lib)


if __name__ == "__main__":
    assemble_args(PARSER, ARGUMENTS)

    ARGS = reform_args(PARSER.parse_args())

    BIN_PATH = join(ARGS.out, "bin")
    VARS_PATH = join(ARGS.out, "vars")
    DIST_PATH = join(ARGS.out, "dist")

    VERSION_STR = get_version(ARGS.mode == "debug")

    LOG_VERBOSE = ARGS.verbose

    if ARGS.mode in ("release", "store"):
        log_print("Removing build path: " + ARGS.out)
        rmtree(ARGS.out, ignore_errors=True)

    if ARGS.copy:
        copy_files(ARGS.sources, BIN_PATH, VARS_PATH, VERSION_STR)

    if ARGS.setup:
        setup_bin = join(BIN_PATH, "setup.exe")

        log_print("Building setup binary: " + setup_bin)
        compile_file(
            join(ARGS.sources["setup.d"]), VARS_PATH, setup_bin, ARGS.mode == "debug")

    if ARGS.updater:
        updater_bin = join(BIN_PATH, "updater.exe")

        log_print("Building updater binary: " + updater_bin)
        compile_file(
            join(ARGS.sources["updater.d"]), VARS_PATH, updater_bin,
            ARGS.mode == "debug")

    if ARGS.deflector:
        deflector_bin = join(BIN_PATH, "deflector.exe")

        log_print("Building deflector binary: " + deflector_bin)
        compile_file(
            join(ARGS.sources["deflector.d"]), VARS_PATH, deflector_bin,
            ARGS.mode == "debug")

    if ARGS.clean:
        clean_files(BIN_PATH)

    if ARGS.mode != "debug":
        for binary in glob(join(BIN_PATH, "*.exe")):
            log_print("Adding icon to executable: " + binary)
            call(["rcedit", binary, "--set-icon", ARGS.sources["icon.ico"]])

    if ARGS.installer:
        license_file = join(VARS_PATH, "license.txt")

        log_print("Creating license file: " + license_file)
        with open(license_file, "w") as out_file:
            with open("LICENSE") as in_file:
                out_file.write(in_file.read())

            out_file.write("\n\n")

            with open(ARGS.sources["libcurl.txt"]) as in_file:
                out_file.write(in_file.read())

        log_print("Making distribution path: " + DIST_PATH)
        makedirs(DIST_PATH, exist_ok=True)

        build_installer(ARGS.sources["installer.iss"], DIST_PATH, VERSION_STR)

    if ARGS.mode == "store":
        pass
