# author leidong

""" Command-line flag library.

Emulates gflags by wrapping cfg.ConfigOpts.

"""
import os, sys

import argparse

from six import moves

def _fixpath(p):
    """Apply tilde expansion and absolutization to a path."""
    return os.path.abspath(os.path.expanduser(p))

def _get_config_dirs(project=None):
    """Return a list of directories where config files may be located.

    :param project: an optional project name

    If a project is specified, following directories are returned::

      ~/.${project}/
      ~/
      /etc/${project}/
      /etc/

    Otherwise, these directories::

      ~/
      /etc/
    """
    cfg_dirs = [
        _fixpath(os.path.join('~', '.' + project)) if project else None,
        _fixpath('~'),
        os.path.join('/etc', project) if project else None,
        '/etc'
    ]

    return list(moves.filter(bool, cfg_dirs))

def _search_dirs(dirs, basename, extension=""):
    """Search a list of directories for a given filename.

    Iterator over the supplied directories, returning the first file
    found with the supplied name and extension.

    :param dirs: a list of directories
    :param basename: the filename, for example 'glance-api'
    :param extension: the file extension, for example '.conf'
    :returns: the path to a matching file, or None
    """
    for d in dirs:
        path = os.path.join(d, '%s%s' % (basename, extension))
        if os.path.exists(path):
            return path

def find_config_files(project=None, prog=None, extension='.conf'):
    """Return a list of default configuration files.

    :param project: an optional project name
    :param prog: the program name, defaulting to the basename of sys.argv[0]
    :param extension: the type of the config file

    We default to two config files: [${project}.conf, ${prog}.conf]

    And we look for those config files in the following directories::

      ~/.${project}/
      ~/
      /etc/${project}/
      /etc/

    We return an absolute path for (at most) one of each the default config
    files, for the topmost directory it exists in.

    For example, if project=foo, prog=bar and /etc/foo/foo.conf, /etc/bar.conf
    and ~/.foo/bar.conf all exist, then we return ['/etc/foo/foo.conf',
    '~/.foo/bar.conf']

    If no project name is supplied, we only look for ${prog.conf}.
    """
    if prog is None:
        prog = os.path.basename(sys.argv[0])

    cfg_dirs = _get_config_dirs(project)

    config_files = []
    if project:
        config_files.append(_search_dirs(cfg_dirs, project, extension))
    config_files.append(_search_dirs(cfg_dirs, prog, extension))

    return list(moves.filter(bool, config_files))


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
