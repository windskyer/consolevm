#!/usr/bin/env python #coding: utf-8
#author leidong

import libvirt
from libvirt import libvirtError

import sys
import os
import re
import shutil
import socket
from distutils.spawn import find_executable
import subprocess

## myself define
#from  xml.buildxml import KvmXml
#from xml.getxml import GetXml

def create_disk(diskpath=None):
    if diskpath is None:
        print "disk path is None"
    
## find cmd from path env 
def get_cmd(cmd=None):
    if cmd is None:
        return(0)
    ret = find_executable(cmd)
    if ret is None:
        raise CreateError("Not Found command %s" % cmd)
    return ret
    


class CreateError(Exception):
    def __init__(self, msg):
         Exception.__init__(self, msg)

class CreateVm(object):
    
    def __init__(self,vmname="test", uri=None):
        if uri is None:
            uri = "qemu:///system"
        if vmname is None:
            vmname = "test"

        self.uri = uri
        self.xmlfile = None
        self.xmlstring = None
        self.diskpath = None
        self.shortname = vmname
        self.uuid = None

        ##conn libvirtd
        self._open

        ## fullname
        self.fullname = self._fullname
        
        ## instance KvmXml 
        self.kx = None

        ## instance GetXml 
        self.gx = None

    @property
    def _fullname(self):
        fullname = [self.shortname]
        pattern = re.compile("(\w*)\.(\w*)\.(\w*)")
        try:
            res = pattern.search(socket.gethostname()).groups()
        except AttributeError:
            res = ['fedora', 'flftuu', 'com']

        domain = ".".join(res[1:]).split('.')
        fullname.extend(domain)
        return str(".".join(fullname))

    @property
    def _open(self):
        try:
            self.virConn = libvirt.open(self.uri)
        except libvirtError , e:
            raise CreateError(" not conn %s  %s" % (self.uri, e.err))

    @property
    def _undefine(self):
        self._virDomain
        self._stop
        self.virtDomain.undefineFlags()


    @property
    def _delete(self):
        self._undefine

    @property
    def _save(self):
        self._virDomain
        self.virtDomain.save(self.savefile)

    @property
    def _define(self):
        try:
            self.virConn.defineXML(self.xmlstring)
        except libvirtError , e:
            raise CreateError(" not define xml file %s" % e.err)

    @property
    def _virDomain(self):

        if self.uuid is not None:
            if self.uuid not in self.list_all_uuid:
                raise CreateError(" %s vm uuid not define " % self.uuid)
            self.virtDomain = self.virConn.lookupByUUIDString(self.uuid)
        else:
            if self.fullname not in self.list_all_vm:
                raise CreateError(" %s vm name  not define " % self.fullname)
            self.virtDomain = self.virConn.lookupByName(self.fullname)

        return self.virtDomain

    @property
    def _run(self):
        if not self.virtDomain.isActive():
            self.virtDomain.create()
            print("%s vm is running" % self.virtDomain.name())
        else:
            print("%s vm is runed" % self.virtDomain.name())

    @property
    def _stop(self):
        if self.virtDomain:
            self.virtDomain.destroyFlags()
        else:
            print("%s vm is not running" % self.virtDomain.name())

    @property
    def _reboot(self):
        self.virtDomain.reboot()

    @property
    def delete(self):
        self._delete
        for disk_dir in self.disk_dirs:
            print disk_dir
            if os.path.isdir(disk_dir):
                shutil.rmtree(disk_dir, True)
                
    @property
    def get_xmlstring(self):
        self._virDomain
        self.xmlstring = self.virtDomain.XMLDesc() 
        return self.xmlstring

    @property
    def is_active(self):
        self._virDomain
        return self.virtDomain.is_Active()

    @property
    def _runsaveimg(self):
        if not self.virtDomain.isActive():
            print "leidong"
            self.virConn.saveImageDefineXML(self.savefile, self.get_xmlstring, libvirt.VIR_DOMAIN_SAVE_RUNNING)
            self._run
        else:
            self._stop
            self.virConn.saveImageDefineXML(self.savefile, self.get_xmlstring, libvirt.VIR_DOMAIN_SAVE_RUNNING)

    def start(self, savedir):
        self._virDomain
        self.is_save = self.is_save(savedir)
        if self.is_save:
            self._runsaveimg
        else:
            self._run

    @property
    def stop(self):
        self._virDomain
        self._stop

    @property
    def reboot(self):
        self._virDomain
        self._reboot

    def save(self,savedir):

        if savedir is None or not os.path.exists(savedir):
            raise CreateError(" not found  %s dir" % savedir)

        self.savefile = os.path.join(savedir ,  self.fullname + ".save")

        if os.path.exists(self.savefile):
            raise CreateError("%s save file is exists" % self.savefile)

        self._save

    def is_save(self, savedir):
        if savedir is None or not os.path.exists(savedir):
            raise CreateError(" not found  %s dir" % savedir)

        self.savefile = os.path.join(savedir ,  self.fullname + ".save")

        if os.path.exists(self.savefile):
            return True
        else:
            return False

    def get_uuid(self, flage=1):
        if not flage:
            self.uuid = self._virDomain.UUIDString()
        else:
            self.uuid = self.kx.uuid

    ## Get all disk dir
    def get_disk_dir(self, gx=None):
        if gx is None:
            raise CreateError(" not define gx ")

        disk_dirs = gx.get_disk_dir
        self.disk_dirs = disk_dirs
        return disk_dirs

    ## Get all disk  path
    def get_disk(self, gx=None):
        if gx is None:
            raise CreateError(" not define gx ")

        self.getxml = gx
        disks = self.getxml.get_disk
        self.disks = disks
        return disks

    ## Create vm disk qcow2
    def create_disk(self, backfile=None):
        for disk in self.disks:
            if os.path.exists(disk) and not os.path.isfile(disk):
                shutil.rmtree(disk, True)

            if not os.path.exists(disk):
                diskname = os.path.basename(disk)
                if backfile is None:
                    backfile = "centos6.6.flftuu.com.raw"

                os.chdir(os.path.dirname(disk))
                qemu_img = get_cmd("qemu-img")
                cmd = "{} create -f qcow2 -b ../template_vm/{} {}".format(qemu_img, backfile, diskname)
                try:
                    subprocess.call(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                except subprocess.CalledProcessError.message as e:
                    raise CreateError("exec {} commond is Fauilter {}".format(cmd , e))


    @property
    def list_all_vm(self):
        domainlist = []
        for domain in self.virConn.listAllDomains():
            domainlist.append(domain.name())

        self.allvm = domainlist
        return domainlist

    @property
    def list_all_uuid(self):
        uuidlist = []
        for domain in self.virConn.listAllDomains():
            uuidlist.append(domain.UUIDString())

        self.allvm = uuidlist
        return uuidlist

    def new_vm(self, kx):
        #if not isinstance(kx, KvmXml):
            #    raise CreateError("kx is not KvmXml instance")

        if self.fullname in self.list_all_vm:
            raise CreateError("%s vm is define " % self.fullname)

        self.kx = kx

        try:
            self.kx.create_xml
        except AttributeError:
            raise CreateError("kx not has create_xml function")
        try:
            self.xmlstring = self.kx.xmlstring
        except AttributeError:
            raise CreateError("kx not has xmlstring function")

        ## define new vm xml file
        self.disks = self.kx.disks
        self.create_disk()
        self._define
        self.get_uuid()
        self.start

if __name__ == "__main__":
    vmname = sys.argv[1:]
    cv = CreateVm(vmname=vmname[0])
    cv.new_vm
