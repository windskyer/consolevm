#coding: utf-8

# vim: tabstop=4 shiftwidth=4 softtabstop=4

#author@: leidong


from vm import CreateVm
from xml import GetXml

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
def start_vm(vmname=None):
    cv = CreateVm(vmname)
    cv.start

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
    print get_mac("gitlab")
    print get_mac("ganglia")
    print get_disk("gitlab")
