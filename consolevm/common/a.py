import cfg
import b
from b import main
CONF = cfg.CONF
prog="consolevm"
usage=prog
description="<options>"
version="2015.1.20"

CONF(prog, usage, description, version)
print CONF.config_file
print CONF
dir(CONF)
#print CONF.qemu.savedir
main
