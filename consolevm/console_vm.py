#coding: utf-8 
#vim: tabstop=4 shiftwidth=4 softtabstop=4 
#author@: leidong


from vm import CreateVm
from xml import KvmXml
from xml import GetXml

from common import cfg 

## get config opts
CONF  = cfg.CONF

## create vm 

def create_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    kx = KvmXml(vmname)
    kx.create_xml
    cv.new_vm(kx)

## delete vm
def delete_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    gx = GetXml(cv.get_xmlstring)
    cv.get_disk_dir(gx)
    cv.delete

## stop vm
def stop_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    cv.stop

## reboot vm
def reboot_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    cv.reboot

## start vm 
def start_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    cv.start(CONF.qemu.savedir)

## status vm
def status_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)

    if cv.is_active:
        print "%s is running" % vmname
    else:
        print "%s is shut off" % vmname

## save vm to savedir
def save_vm(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    cv.save(CONF.qemu.savedir)

def get_mac(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    gx = GetXml(cv.get_xmlstring)
    return gx.get_macaddr

## Get disk file path
def get_disk(vmname=None):
    cv = CreateVm(vmname, CONF.url, CONF.ostype)
    gx = GetXml(cv.get_xmlstring)
    return cv.get_disk(gx)

## set optsions values
options = {
    "delete": delete_vm,
    "stop": stop_vm,
    "reboot": reboot_vm,
    "start": start_vm,
    "getdisk": get_disk,
    "getmac": get_mac,
    "save": save_vm,
    "status": status_vm,
    "create": create_vm,

}

def main(opts=None):
    if opts is None: 
        opts = ["status"]

    if not isinstance(opts,list):
        opts = [opts]

    names = []
    if not isinstance(CONF.name, list):
        names.append(CONF.name)
    else:
        names = CONF.name

    for o in opts:
        opt = options.get(o)
        for name in names:
            opt(name)


if __name__ == "__main__":
    #create_vm_args("console_vm", "console vm")
    #print get_mac("gitlab")
    #print get_mac("ganglia")
    #print get_disk("gitlab")
    start_vm()
    #save_vm("github")
