#!/usr/bin/env python
#coding: utf-8
#author leidong


from lxml import etree
import re
import os


class GetError(Exception):
    def __init__(self, msg):
        Exception.__init__(self.msg)

class GetXml(object):
    def __init__(self, xmlstring, is_active=False):
        if xmlstring is None:
            raise GetError("xmlstring is None")

        self.xmlstring = xmlstring
        self.doc = etree.fromstring(self.xmlstring)
        self.fullname = self._fullname
        self.is_active = is_active

    ## get fullname from xml file
    @property
    def _fullname(self):
        fullnamexmls = self.doc.xpath("//domain/name")
        for fullnamexml in fullnamexmls:
            fullname = fullnamexml.text
        return fullname

    ## get disk file 
    @property
    def get_disk(self):
        disks = []
        sourcelist = self.doc.xpath("//domain/devices/disk/source")
        for source in sourcelist:
            disks.append(source.get('file'))

        self.disks = disks
        return disks

    @property
    def get_disk_dir(self):
        diskdirs = []
        for disk in self.get_disk:
            diskdirs.append(os.path.dirname(disk))

        self.diskdirs = diskdirs
        return diskdirs

    @property
    def get_macaddr(self):
        macaddrs = {}
        #macaddrlist = self.doc.xpath("//domain/devices/interface/mac")
        #for macaddr in macaddrlist:
            #    macaddrs.append(macaddr.get("address"))
        interlist = self.doc.xpath("//domain/devices/interface")
        i = 1
        for inter in interlist:
            macdict = {}
            netdict = {}
            netdev = None
            for chilist in inter.getchildren():
                if chilist.tag == "mac" :
                    macdict["mac"] = chilist.get("address")
                if chilist.tag == "source" :
                    macdict["network"] = chilist.get("network")
                if chilist.tag == "target" :
                    netdev = chilist.get("dev")
            if netdev is None:
                netdict["dev%s" % i] = macdict
                i += 1
            else:
                netdict[netdev] = macdict

        macaddrs[self.fullname] = netdict
        return macaddrs
