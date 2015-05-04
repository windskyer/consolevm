# author leidong

""" Command-line flag library.

Emulates gflags by wrapping cfg.ConfigOpts.

"""
import os, sys

import argparse

def create_vm_args(prog, usage):
    oparser = argparse.ArgumentParser(prog=prog, usage=usage, description='%(prog)s - consolevm args')

    version = usage
    oparser.add_argument('-v', '--version',
                         action='version',
                         version=version,
                         help='Print more verbose output (set logging level to '
                         'INFO instead of default WARNING level).')

    oparser.add_argument('-D', '--debug',
                         action='store_false',
                         default=False,
                         help='Print debugging output (set logging level to '
                         'DEBUG instead of default WARNING level).'),

    oparser.add_argument('--shorname', '-N',
                         nargs='?',
                         const='',
                         help='Vm shorname (default: test); eg if vm name is test.flftuu.com you mush input test (shortname)',
                         default='test',
                        )

    return oparser.parse_args()
