#! py -3

# from glob import glob
# from os.path import join
# from os import remove, makedirs
# from shutil import copyfile, rmtree
from argparse import ArgumentParser
# from subprocess import check_output, call

PARSER = ArgumentParser(description="Search Deflector Build Script")
ARGUMENTS = {
    "all": {
        "flags": ("-a", "-all"),
        "action": "store_true",
        "help": "build all binaries"
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
        "default": "release",
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
    if args.mode == "debug":
        args.installer = False
    elif args.mode == "release":
        args.all = True
    elif args.mode == "store":
        args.all = True

    if args.all:
        args.setup = True
        args.updater = True
        args.deflector = True

    if args.mode == "r":
        args.mode = "release"
    elif args.mode == "s":
        args.mode = "store"
    elif args.mode == "d":
        args.mode = "debug"

    if args.mode == "release":
        args.installer = True
        args.clean = True
    elif args.mode == "store":
        args.clean = True

    return args


def build_setup():
    pass


def build_updater():
    pass


def build_deflector():
    pass


def build_installer():
    pass


def copy_files():
    pass


def clean_files():
    pass


if __name__ == "__main__":
    assemble_args(PARSER, ARGUMENTS)
    ARGS = reform_args(PARSER.parse_args())

    if ARGS.setup:
        build_setup()

    if ARGS.updater:
        build_updater()

    if ARGS.deflector:
        build_deflector()

    if ARGS.installer:
        build_installer()

    if ARGS.copy:
        copy_files()

    if ARGS.clean:
        clean_files()
