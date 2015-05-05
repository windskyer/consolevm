#coding: utf-8

# vim: tabstop=4 shiftwidth=4 softtabstop=4

#author@: leidong


from vm import CreateVm
from xml import GetXml

from config import create_vm_args

__all__ = ["delete_vm" , "stop_vm" , "reboot_vm" , "start_vm" , "get_disk" , "get_mac", "save_vm"]



## delete vm
def delete_vm(vmname=None):
    cv = CreateVm(vmname)
    gx = GetXml(cv.get_xmlstring)
    cv.get_disk_dir(gx)
    cv.delete

## stop vm
def stop_vm(vmname=None):
    cv = CreateVm(vmname)
    cv.stop

## reboot vm
def reboot_vm(vmname=None):
    cv = CreateVm(vmname)
    cv.reboot

## start vm 
def start_vm(vmname=None,savedir='/var/lib/libvirt/qemu/save'):
    cv = CreateVm(vmname)
    cv.start(savedir)

## save vm to savedir
def save_vm(vmname=None, savedir='/var/lib/libvirt/qemu/save'):
    cv = CreateVm(vmname)
    cv.save(savedir)

def get_mac(vmname=None):
    cv = CreateVm(vmname)
    gx = GetXml(cv.get_xmlstring)
    return gx.get_macaddr

## Get disk file path
def get_disk(vmname=None):
    cv = CreateVm(vmname)
    gx = GetXml(cv.get_xmlstring)
    return cv.get_disk(gx)

if __name__ == "__main__":
    #create_vm_args("console_vm", "console vm")
    #print get_mac("gitlab")
    #print get_mac("ganglia")
    #print get_disk("gitlab")
    start_vm("github")
    #save_vm("github")
