#coding: utf-8
# vim: tabstop=4 shiftwidth=4 softtabstop=4
#author@: leidong
 
__version__ = "2015.5.1"
__description__ = ""

from common import cfg

CONF = cfg.CONF
reg_opts = [
    cfg.Opt('url',
            default='qemu+tcp://127.0.0.1:16509/system',
            nargs='?',
            help='libvirtd server IP default : qemu+tcp://127.0.0.1:16509/system'),

    cfg.Opt('name',
            short='n',
            default='test',
            nargs='+',
            help='qemu vm name + eg -n test1 test2'),

    cfg.Opt('ostype',
            short='o',
            default='linux',
            nargs='?',
            help='create qemu vm type eg -o linux or -o windows'),
]

CONF.register_opts(reg_opts)

def createvm_reg_opts():
    prog="consolevm"
    usage="create vm"
    description=__description__
    version=__version__
    CONF(prog, usage, description, version)

