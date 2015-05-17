import cfg
CONF = cfg.CONF
reg_opts = [
            cfg.Opt('bind_host',
                            short='b',
                            default='0.0.0.0',
                            nargs='+',
                            help='libvirtd server IP address to listen on.'),
        ]
CONF.register_opts(reg_opts)

def main():
    print CONF.qemu.savedir

