# author leidong

""" Command-line flag library.

Emulates gflags by wrapping cfg.ConfigOpts.

"""
import os, sys
from six import moves

## argparse
import argparse
## configure
from ConfigParser import ConfigParser
from ConfigParser import re

import collections

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

class ConfParser(ConfigParser):

    def _pre_setup_(self):
        self.read(self.filenames)

    def _setup_(self):
        self.groups = self.sections()
        self._all_args()

    def __call__(self, filenames):
        self.args_sections = {} 
        self.filenames = filenames
        self._pre_setup_()
        self._setup_()
        self.group = self.sections()

    ## return dict
    def _all_args(self):
        secs = {}
        opts = {}
        values = {}
        for sec in  self.sections():
            keys = self.options(sec) 
            opts.setdefault(sec, keys)
            for key in keys:
                values.setdefault(key, self.get(sec, key))
            secs.setdefault(sec, values)

        self._opts = opts
        self.args_sections = secs

class OptGroup(object):
    """
      name:
        the name of the group
      title:
        the group title as displayed in --help
      help:
        the group description as displayed in --help
    """
    def __init__(self, name):
        """Constructs an OptGroup object.
        :param name: the group name
        :param title: the group title for --help
        :param help: the group description for --help
        """
        self.cparser = None
        self.name = name
        self._opts = None
        self._argparse_group = None
        self.pre_setup

    @property
    def pre_setup(self):
        self._clear
        self._get_argparse_group
        self._get_argparse_opts
    
    def _gat_argparse_value(self, value):
        return self._opts.get(value, None)

    @property
    def _get_argparse_opts(self):
        if self.name in self._argparse_group:
            self._opts = self.cparser.sections.get(self.name)
        return self._opts
            
    @property
    def _get_argparse_group(self):
        if self._argparse_group is None:
            """Build an argparse._ArgumentGroup for this group."""
            self._argparse_group = self.cparser.groups
        return self._argparse_group

    @property
    def _clear(self):
        """Clear this group's option parsing state."""
        self._argparse_group = None

                

## args Namespace
class _Namespace(argparse.Namespace):
    def __init__(self, conf):
        self._conf = conf 


## Config opts 
class _ConfigOpt(object):
    """
      filenames:
        the configure file name
      project:
        the project name 
    """
    def __init__(self, namespace):
        self.filenames = set()
        self.project = None
        self._argparse_group = None
        self._namespace = namespace
        self._reg_opts = []

    def _setup_(self):
        self._register_config
        self._add_argument
        self._oparser.parse_args(namespace=self._namespace)
        if self._namespace.config_file is not None:
            self._pre_setup_(self._namespace.config_file, self.project)
        else:
            self._pre_setup_(filenames=None, project=self.project)

    def _pre_setup_(self, filenames=None, project=None):
        file_ok = []
        if project is None:
            project = os.path.basename(sys.argv[0])

        if filenames is None:
            self.filenames = find_config_files(project)  
        else:
            for filename in filenames:
                file_ok.append(os.path.isfile(filename))
            else:
                if len(list(moves.filter(bool, file_ok))) < 1:
                    self.filenames = find_config_files(project)  
        return file_ok

    def __call__(self, prog, usage, description, version):
        self.project = prog
        self.version = version
        self._oparser = argparse.ArgumentParser(prog=prog, 
                                                usage=usage, 
                                                description=description, 
                                                add_help=False,
                                                epilog='See "consolevm help COMMAND" '
                                                       'for help on a specific command.',
                                               )


        self._setup_()
        self.confparser = ConfParser()
        self.confparser(self.filenames)
    
    def _get(self, value, group):
        """
        param name: the name of the group
        param group: an OptGroup object
        """
        self._get_argparse_opts(group)

        return self._opts.get(value)

    def _gat_argparse_value(self, value):
        return self.confparser._opts.get(value, None)

    def _get_argparse_opts(self, group):
        if group in self._get_argparse_group:
            self._opts = self.confparser.args_sections.get(group)
        return self._opts
            
    @property
    def _get_argparse_group(self):
        if self._argparse_group is None:
            """Build an argparse._ArgumentGroup for this group."""
            self._argparse_group = self.confparser.groups
        return self._argparse_group

    @property
    def _register_config(self):

        self._oparser.add_argument('-h', '--help',
                                   acton='store_true',
                                   help=argparse.SUPPRESS)

        self._oparser.add_argument('-v', '--version',
                                   action='version',
                                   version=self.version,
                                  )

        self._oparser.add_argument('-d', '--debug',
                                   action='store_false',
                                   default=False,
                                   help="Print debugging output")

        self._oparser.add_argument('--config-file',
                                   nargs='?',
                                   help='Path to a config file to use. Multiple config '
                                   'files can be specified, with values in later '
                                   'files taking precedence. The default files '
                                  )
            
    @property
    def _add_argument(self):
        for ret_opt in self._reg_opts:
            args = ret_opt[0]
            kwargs = ret_opt[1]
            self._oparser.add_argument(*args, **kwargs)

    def register_opt(self, opt):
        self._reg_opts.append(opt._add_to_argparse())


    class GroupAttr(collections.Mapping):
        def __init__(self, conf, group):
                """Construct a GroupAttr object.
    
                :param conf: a ConfigOpts object
                :param group: an  group name
                """
                self._conf = conf
                self._group = group
    
        def __getattr__(self, value):
            """Look up an option value and perform template substitution."""
            return self._conf._get(value, self._group)
    
        def __getitem__(self, key):
            """Look up an option value and perform string substitution."""
            return self.__getattr__(key)
    
        def __contains__(self, key):
            """Return True if key is the name of a registered opt or group."""
            return key in self._group._opts
    
        def __iter__(self):
            """Iterate over all registered opt and group names."""
            for key in self._group._opts.keys():
                yield key
    
        def __len__(self):
            """Return the number of options and option groups."""
            return len(self._group._opts)

class Opt(object):

    def __init__(self, name , short=None , prefix='', **kwargs):
        self.name = name
        self.short = short
        self.prefix=prefix
        self.kwargs = kwargs

    def _add_to_argparse(self, positional=False):
        def hyphen(arg):
            return arg if not positional else ''

        args = [hyphen('--') + self.prefix + self.name]
        if self.short:
            args.append(hyphen('-') + self.short)

        args.reverse()
        return (args, self.kwargs)
        
class ConfigOpts(object):
    def __init__(self):
        self._namespace = _Namespace(self)
        self._Config = _ConfigOpt(self._namespace)

    def __call__(self, prog, usage, description, version):
        self._Config(prog, usage, description, version)

    def __getattr__(self, name):
        if name in self._Config.confparser._opts:
            return self._Config.GroupAttr(self._Config, name)  
        else:
            return getattr(self._namespace, name)

    def __getitem__(self, key):
        """Look up an option value and perform string substitution."""
        return self.__getattr__(key)

    def register_opt(self, opt):
        """
        :param opt is Opt object
        """
        self._Config.register_opt(opt)

    def register_opts(self, opts):
        """
        :param opts is more Opt object
        """
        for opt in opts:
            self.register_opt(opt)

    ## register subcommond opts
    def sub_commond_register_opt(self, opt, subname):
        pass

    def sub_commond_register_opts(self, opts, subname):
        pass
            

CONF = ConfigOpts() 

if __name__ == '__main__':
    #CONF  = ConfigOpts() 
    prog="consolevm"
    usage=prog
    description="<options>"
    version="2015.1.20"
    reg_opts = [
        Opt('bind_host',
            short='b',
            default='0.0.0.0',
            nargs='+',
            help='libvirtd server IP address to listen on.'),
    ]
    CONF.register_opts(reg_opts)
    CONF(prog, usage, description, version)
    print CONF.config_file
    print CONF.bind_host
    print CONF.libvirtd.ip
    print CONF.libvirtd['ip']
    print CONF.qemu.savedir
