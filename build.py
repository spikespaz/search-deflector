#! py -3

from os.path import dirname, exists, basename, join as path_join
from subprocess import call, check_output
from argparse import ArgumentParser
from shutil import rmtree, copyfile
from os import remove, makedirs
from glob import glob

ASSETS_PATH = "assets"
SOURCE_PATH = "source"
LIBS_PATH = "libs"
PACK_PATH = "pack"
LANG_PATH = "lang"

BIN_PATH = "build/bin"
DIST_PATH = "build/dist"
VARS_PATH = "build/vars"
STORE_PATH = "build/store"

CONFIGURE_BIN = path_join(BIN_PATH, "configure.exe")
DEFLECTOR_BIN = path_join(BIN_PATH, "deflector.exe")
PACKAGE_FILE = path_join(DIST_PATH, "SearchDeflector-Package.appx")

PARSER = ArgumentParser(description="Search Deflector Build Script")

ARGUMENTS = {
    "mode": {
        "flags": ("-m", "--mode"),
        "choices": ("classic", "store"),
        "help": "preset of things to build",
    },
    "build": {
        "flags": ("-b", "--build"),
        "action": "append",
        "choices": ("configure", "deflector", "installer", "package"),
        "default": [],
        "help": "parts of the program to build",
    },
    "debug": {
        "flags": ("-d", "--debug"),
        "action": "store_true",
        "help": "enable compiler debug flags",
    },
    "clean": {
        "flags": ("-c", "--clean"),
        "action": "store_true",
        "help": "clean up temporary files",
    },
    "icon": {
        "flags": ("-i", "--icon"),
        "action": "append",
        "choices": ("configure", "deflector"),
        "default": [],
        "help": "add the icon to the binaries specified."
    },
    "version": {"flags": ("-v", "--version"), "help": "version string to use in build"},
    "silent": {
        "flags": ("-s", "--silent"),
        "action": "store_true",
        "help": "only print errors to console",
    },
}

LOG_VERBOSE = True


def log_print(*args, **kwargs):
    if LOG_VERBOSE:
        print(*args, **kwargs)


def get_version():
    return check_output("git describe --tags --abbrev=0").decode().strip()


def assemble_args(parser, arguments):
    for dest, kwargs in arguments.items():
        flags = kwargs.pop("flags")

        if isinstance(flags, str):
            parser.add_argument(flags, dest=dest, **kwargs)
        else:
            parser.add_argument(*flags, dest=dest, **kwargs)


def copy_file(from_file, to_file):
    log_print("Copying file: " + to_file)
    copyfile(from_file, to_file)


def copy_dir(from_dir, to_dir):
    for file in glob(path_join(from_dir, "*.*")):
        copy_file(file, path_join(to_dir, basename(file)))


def create_directory(directory):
    if not exists(directory):
        log_print("Creating directory: " + directory)
        makedirs(directory, exist_ok=True)


def delete_directory(directory):
    if exists(directory):
        log_print("Deleting directory: " + directory)
        rmtree(directory, ignore_errors=True)


def compile_file(source, binary, debug=True, console=False, args=None):
    log_print("Compiling binary: " + binary)

    command = ["ldc2", source, "-i", "-I", dirname(source), "-J", VARS_PATH, "-of", binary, "-m32"]

    if debug:
        command.extend(["-gc", "-d-debug", "-L/subsystem:console"])
    else:
        command.extend(["-O3", "-ffast-math", "-release"])

        if not console:
            command.extend(["-L/subsystem:windows", "-L/entry:wmainCRTStartup"])

    if args:
        command.extend(args)

    log_print(">", *command)
    call(command)


def add_icon(binary):
    log_print("Adding icon: " + binary)

    call(["rcedit", "--set-icon", path_join(ASSETS_PATH, "logo.ico"), binary])


def copy_files(version):
    copy_file(path_join(LIBS_PATH, "libcurl.dll"), path_join(BIN_PATH, "libcurl.dll"))
    copy_file(path_join(LIBS_PATH, "engines.txt"), path_join(BIN_PATH, "engines.txt"))

    copy_file(path_join(LIBS_PATH, "issue.md"), path_join(VARS_PATH, "issue.md"))

    copy_dir(LANG_PATH, path_join(BIN_PATH, "lang"))

    version_file = path_join(VARS_PATH, "version.txt")
    log_print("Creating file: " + version_file)

    with open(version_file, "w") as out_file:
        out_file.write(version)

    license_file = path_join(VARS_PATH, "license.txt")
    log_print("Creating file: " + license_file)

    with open(license_file, "w") as out_file:
        with open("LICENSE") as in_file:
            out_file.write(in_file.read())

        out_file.write("\n")

        with open(path_join(LIBS_PATH, "libcurl.txt")) as in_file:
            out_file.write(in_file.read())


if __name__ == "__main__":
    assemble_args(PARSER, ARGUMENTS)
    ARGS = PARSER.parse_args()

    if ARGS.silent:
        LOG_VERBOSE = False

    if not ARGS.version:
        ARGS.version = get_version()

    log_print("Using version number: " + ARGS.version)

    if ARGS.mode == "classic" and not ARGS.clean and not ARGS.icon:
        build_set = set(ARGS.build)
        build_set.update(("configure", "deflector", "installer"))
        ARGS.build = tuple(build_set)

        ARGS.clean = True

        delete_directory("build/bin")
        delete_directory("build/vars")
    elif ARGS.mode == "store" and not ARGS.clean and not ARGS.icon:
        build_set = set(ARGS.build)
        build_set.update(("configure", "deflector", "package"))
        ARGS.build = tuple(build_set)

        ARGS.clean = True

        delete_directory("build/bin")
        delete_directory("build/vars")
        delete_directory("build/store")

    if "configure" in ARGS.build:
        create_directory(BIN_PATH)
        create_directory(path_join(BIN_PATH, "lang"))
        create_directory(VARS_PATH)

        log_print("Building configure binary: " + CONFIGURE_BIN)

        copy_files(ARGS.version)
        compile_file(
            path_join(SOURCE_PATH, "configure.d"),
            CONFIGURE_BIN,
            ARGS.debug,
            args=None if "package" in ARGS.build else ["-d-version", "free_version"],
        )

        ARGS.icon.append("configure")

    if "deflector" in ARGS.build:
        create_directory(BIN_PATH)
        create_directory(VARS_PATH)

        log_print("Building deflector binary: " + DEFLECTOR_BIN)

        copy_files(ARGS.version)
        compile_file(
            path_join(SOURCE_PATH, "deflector.d"),
            DEFLECTOR_BIN,
            ARGS.debug,
            args=None if "package" in ARGS.build else ["-d-version", "free_version"],
        )

        ARGS.icon.append("deflector")

    if "configure" in ARGS.icon:
        add_icon(CONFIGURE_BIN)

    if "deflector" in ARGS.icon:
        add_icon(DEFLECTOR_BIN)

    if ARGS.clean:
        for file in glob(path_join(BIN_PATH, "*.pdb")):
            log_print("Removing debug file: " + BIN_PATH + "/" + file)
            remove(file)

        for file in glob(path_join(BIN_PATH, "*.obj")):
            log_print("Removing object file: " + BIN_PATH + "/" + file)
            remove(file)

    if "installer" in ARGS.build:
        create_directory(DIST_PATH)

        log_print("Making installer executable: " + path_join(DIST_PATH, "SearchDeflector-Installer.exe"))

        command = 'iscc "/O{}" /Q "/DAppVersion={}" "{}/installer.iss"'.format(
            DIST_PATH, ARGS.version, PACK_PATH
        )

        log_print("> " + command)
        call(command)

    if "package" in ARGS.build:
        create_directory(DIST_PATH)
        create_directory(STORE_PATH)

        log_print("Making store package: " + PACKAGE_FILE)

        create_directory(path_join(STORE_PATH, "Assets"))
        create_directory(path_join(STORE_PATH, "lang"))

        copy_file(path_join(ASSETS_PATH, "logo.png"), path_join(STORE_PATH, "Assets/Logo-Store.png"))
        copy_file(path_join(ASSETS_PATH, "logo_44.png"), path_join(STORE_PATH, "Assets/Logo-44.png"))
        copy_file(path_join(ASSETS_PATH, "logo_150.png"), path_join(STORE_PATH, "Assets/Logo-150.png"))

        copy_file(path_join(BIN_PATH, "configure.exe"), path_join(STORE_PATH, "configure.exe"))
        copy_file(path_join(BIN_PATH, "deflector.exe"), path_join(STORE_PATH, "deflector.exe"))
        copy_file(path_join(BIN_PATH, "engines.txt"), path_join(STORE_PATH, "engines.txt"))

        copy_dir(path_join(BIN_PATH, "lang"), path_join(STORE_PATH, "lang"))
        
        manifest_file = path_join(STORE_PATH, "AppxManifest.xml")
        log_print("Creating file: " + manifest_file)

        with open(manifest_file, "w") as out_file:
            with open(path_join(PACK_PATH, "appxmanifest.xml")) as in_file:
                out_file.write(in_file.read().replace("{{version}}", ARGS.version + ".0"))

        log_print("Packing file: " + PACKAGE_FILE)

        command = 'MakeAppx pack /d "{}" /p "{}" /o'.format(STORE_PATH, PACKAGE_FILE)
        log_print("> " + command)

        call(command)
