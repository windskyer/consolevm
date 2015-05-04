#!/usr/bin/env python
#coding: utf-8
#author leidong

import libvirt
from libvirt import libvirtError

import sys
import re
import socket

## myself define
from  xml import KvmXml

def create_disk(diskpath=None):
    if diskpath is None:
        print "disk path is None"
    
class CreateError(Exception):
    def __init__(self, msg):
         Exception.__init__(self, msg)

class CreateVm(object):
    
    def __init__(self,vmname="test", uri=None):
        if uri is None:
            uri = "qemu:///system"

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

    @property
    def _fullname(self):
        fullname = [self.shortname]
        pattern = re.compile("(\w*)\.(\w*)\.(\w*)")
        res = pattern.search(socket.gethostname()).groups()
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
    def _define(self):
        try:
            self.virConn.defineXML(self.xmlstring)
        except libvirtError , e:
            raise CreateError(" not define xml file %s" % e.err)

    @property
    def _virDomain(self):
        if self.uuid is not None:
            self.virtDomain = self.virConn.lookupByUUIDString(self.uuid)
        else:
            self.virtDomain = self.virConn.lookupByName(self.fullname)
        return self.virtDomain

    @property
    def _run(self):
        if not self.virtDomain:
            self.virtDomain.create()
        else:
            print("%s vm is running" % self.virtDomain.name())

    @property
    def _stop(self):
        if self.virtDomain:
            self.virtDomain.destroyFlags()
        else:
            print("%s vm is not running" % self.virtDomain.name())

    @property
    def _reboot(self):
        self.virtDomain.reboot()

    def delete(self):
        pass

    @property
    def start(self):
        self._virDomain
        self._run

    @property
    def stop(self):
        self._virDomain
        self._stop

    @property
    def reboot(self):
        self._virtDomain
        self._reboot

    def get_uuid(self, flage=1):
        if not flage:
            self.uuid = self._virDomain.UUIDString()
        else:
            self.uuid = self.kx.uuid

    def new_vm(self, kx):
        if not isinstance(kx, KvmXml):
            raise CreateError("kx is not KvmXml instance")

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
        self._define
        self.get_uuid()
        self.start

        

if __name__ == "__main__":
    vmname = sys.argv[1:]
    cv = CreateVm(vmname=vmname[0])
    cv.start
