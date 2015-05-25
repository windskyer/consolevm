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
from consolevm.actions import actions_module

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

class ArgumentParser(argparse.ArgumentParser):

    def __init__(self, *args, **kwargs):
        super(ArgumentParser, self).__init__(*args, **kwargs)

    def error(self, message):
        """error(message: string)

        Prints a usage message incorporating the message to stderr and
        exits.
        """
        self.print_usage(sys.stderr)
        #FIXME(lzyeval): if changes occur in argparse.ArgParser._check_value
        choose_from = ' (choose from'
        progparts = self.prog.partition(' ')
        self.exit(2, "error: %(errmsg)s\nTry '%(mainp)s help %(subp)s'"
                     " for more information.\n" %
                     {'errmsg': message.split(choose_from)[0],
                      'mainp': progparts[0],
                      'subp': progparts[2]})


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
        self._sub_reg_opts = []
        self._sub_reg_coms = []
        self._sub_commonds = {}
        self.subcommands = {}


    def _setup_(self):
        self._register_config
        self._add_argument

        self._oparser.parse_known_args(namespace=self._namespace)

        self.subparsers = self._oparser.add_subparsers( 
                                                       metavar='<subcommand>')

        self._reg_help

        self._sub_add_argument
        if self._namespace.help or not sys.argv[1:]:
            self._oparser.print_help()
            sys.exit(0)

        self._oparser.parse_args(namespace=self._namespace)
        if self._namespace.func == self.vm_help:
            self.vm_help(self._namespace)
            sys.exit(0)

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

    def __call__(self, prog,description, version):
        self.project = prog
        self.version = version
        self._oparser = ArgumentParser(prog=prog, 
                                       description=description, 
                                       add_help=False,
                                       epilog='See "consolevm help subcommand" '
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
                                   action='store_true',
                                   help=argparse.SUPPRESS)

        self._oparser.add_argument('-V', '--version',
                                   action='version',
                                   version=self.version,
                                  )

        self._oparser.add_argument('-d', '--debug',
                                   action='store_true',
                                   help="Print debugging output")

        self._oparser.add_argument('--config-file',
                                   nargs='?',
                                   help='Path to a config file to use. Multiple config '
                                   'files can be specified, with values in later '
                                   'files taking precedence. The default files ',
                                  )
        self._oparser.add_argument('--config_file',
                                   help=argparse.SUPPRESS,
                                  )
        
    @property
    def _reg_help(self):

        subparser = self.subparsers.add_parser('help', 
                                               add_help=False, 
                                               help='Shows help about this program or one of its subcommonds',
                                              )
        subparser.add_argument('command',
                               nargs='?',
                               metavar='<subcommand>',
                               help='Display help for <subcommand>',
                              )

        subparser.add_argument('-h', '--help',
                               action='help',
                               help=argparse.SUPPRESS,)

        subparser.set_defaults(func=self.vm_help)
        self.subcommands['help'] = subparser
        
    @property
    def _add_argument(self):
        for ret_opt in self._reg_opts:
            args = ret_opt[0]
            kwargs = ret_opt[1]
            self._oparser.add_argument(*args, **kwargs)

    @property
    def _sub_add_argument(self):
        for k, v in self._sub_commonds.items():
            command = k.replace('_', '-')
            attr = '_'.join(['vm', k])
            desc = v.get('desc') 
            values = v.get('values') 
            subparser = self.subparsers.add_parser(command, add_help=False, **desc)

            for args, kwargs in values:
                subparser.add_argument(*args, **kwargs)

            subparser.add_argument('-h', '--help',
                                   action='help',
                                   help=argparse.SUPPRESS,)

            callback = getattr(actions_module, attr)
            subparser.set_defaults(func=callback)
            self.subcommands[command] = subparser

    def register_opt(self, opt):
        self._reg_opts.append(opt._add_to_argparse())

    def sub_commond_register_opt(self, opt, subname):
        #self._sub_reg_opts.append({subname.name : opt._add_to_argparse()})

        self._sub_reg_opts.append(opt._add_to_argparse())

        values = {'values' : self._sub_reg_opts}
        desc = {'desc' : subname._add_to_sub_commond().get(subname.name)}
        values.update(desc)
        #self._sub_reg_coms.append(subname._add_to_sub_commond())
        self._sub_commonds.setdefault(subname.name, values)

    def vm_help(self, args):
        """
        Display help about this program or one of its subcommands.
        """
        if args.command:
            if args.command in self.subcommands:
                self.subcommands[args.command].print_help()
            else:
                raise Exception("'%s' is not a valid subcommand" %
                                       args.command)
        else:
            self._oparser.print_help()


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

    def __init__(self, name , short=None , prefix='', subcom=False, **kwargs):
        self.name = name
        self.short = short
        self.prefix=prefix
        self.subcom = subcom
        self.kwargs = kwargs

    def _add_to_argparse(self, positional=False):
        def hyphen(arg):
            return arg if not positional else ''

        if self.subcom:
            args = []
            args.append(self.name) 

        else:
            args = [hyphen('--') + self.prefix + self.name]
            if self.short:
                args.append(hyphen('-') + self.short)

        args.reverse()
        return (args, self.kwargs)

    def __repr__(self):
        return "'%s' is Opt object instance" % self.name

    def __str__(self):
        return "'%s' is Opt object instance" % self.name

class Sub(object):
    def __init__(self, name, **kwargs):
        self.name = name
        self.kwargs = kwargs
        
    def _add_to_sub_commond(self, positional=False):
        args = {}
        args.setdefault(self.name.lower(), self.kwargs)
        return args

    def __repr__(self):
        return "'%s' is Sub object instance" % self.name

    def __str__(self):
        return "'%s' is Sub object instance" % self.name

class ConfigOpts(object):
    def __init__(self):
        self._namespace = _Namespace(self)
        self._Config = _ConfigOpt(self._namespace)

    def __call__(self, prog,description, version):
        self._Config(prog,description, version)

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
        self._Config.sub_commond_register_opt(opt, subname)

    def sub_commond_register_opts(self, opts, subname):
        self._Config._sub_reg_opts = []
        for opt in opts:
            self.sub_commond_register_opt(opt, subname)
            
    def print_help(self):
        self._namespace.print_help()

CONF = ConfigOpts() 

if __name__ == '__main__':
    #CONF  = ConfigOpts() 
    prog="consolevm"
    usage=prog + "adfafadfadfafdfadfa"
    description="Command-line interface to the consolevm API."
    version="2015.1.20"

    reg_opts = [
        Opt('bind_host',
            short='b',
            default='0.0.0.0',
            nargs='+',
            help='libvirtd server IP address to listen on.'),
    ]
    sub_reg_opts = [
        Opt('name',
            metavar='<name>',
            subcom=True,
            nargs='+',
            help='libvirtd vm name'),
    ]
    sub_reg_comm = [
        Sub('list',
            help='list all libvirtd vm '),
    ]


    CONF.sub_commond_register_opts(sub_reg_opts, sub_reg_comm[0])
    CONF.register_opts(reg_opts)
    CONF(prog,  description, version)
    print CONF.config_file
    print CONF.bind_host
    print CONF.libvirtd.ip
    print CONF.libvirtd['ip']
    print CONF.qemu.savedir
    CONF.func(CONF)
