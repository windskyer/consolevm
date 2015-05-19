#coding: utf-8
# vim: tabstop=4 shiftwidth=4 softtabstop=4
#author@: leidong
 
"""
Command-line interface to the conselovm API.
"""

__version__ = "2015.5.1"
__description__ = ""

from common import cfg
from common import utils

CONF = cfg.CONF
reg_opts = [
    cfg.Opt('url',
            default='qemu+tcp://127.0.0.1:16509/system',
            nargs='?',
            help='libvirtd server IP default : qemu+tcp://127.0.0.1:16509/system'),


    cfg.Opt('ostype',
            short='o',
            default='linux',
            nargs='?',
            help='create qemu vm type eg -o linux or -o windows'),
]
## register opts
CONF.register_opts(reg_opts)

## register sub commond
sub_reg_opts = [
    cfg.Opt('name',
            subcom=True,
            default=utils.env('TEST_NAME',dfault='test'),
            nargs='+',
            help='qemu vm name  eg  test1 test2'),

    cfg.Opt('alls',
            short='a',
            action='store_true',
            default=utils.env('ALLS',dfault='False'),
            help='list all kvm vm'),
]

sub_reg_comm = {
    'list':
        cfg.Sub('list',
            help='list all libvirtd vm '),

    'create':
        cfg.Sub('create',
            help='create some new vm type is linux or windows'),
    'delete':
        cfg.Sub('delete',
            help='delete some vm type but this is exists'),
    'stop':
        cfg.Sub('stop',
            help='stop some vm '),
    'reboot':
        cfg.Sub('reboot',
            help='reboot some vm '),
    'start':
        cfg.Sub('start',
            help='start some vm but this is exists '),
    'status':
        cfg.Sub('status',
            help='status some vm '),
    'save':
        cfg.Sub('save',
            help='save some vm current status '),
    'getmac':
        cfg.Sub('getmac',
            help='getmac some vm'),
    'getdisk':
        cfg.Sub('getdisk',
            help='getdisk some vm'),
}

#print sub_reg_opts
#CONF.sub_commond_register_opts(sub_reg_opts, sub_reg_comm.get('list'))
for k in sub_reg_comm.keys():
    if k == 'list':
        CONF.sub_commond_register_opts(sub_reg_opts[1:], sub_reg_comm.get(k))
    else:
        CONF.sub_commond_register_opts(sub_reg_opts[:1], sub_reg_comm.get(k))
