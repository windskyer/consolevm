#!/usr/bin/env python
#coding: utf-8
#author leidong


import lxml
import socket
import re
import random
import os, sys
import uuid
from multiprocessing import cpu_count


from lxml import etree 


#root = etree.Element("root")
#root.append(etree.Element("child1"))
#print(etree.tostring(root, pretty_print=True))


## create new xml to do craete new vm 
class KvmXml(object):

    UNIT_LIST={
        "K":'KiB',
        "M":'MiB',
        "G":'GiB',
    }

    top_dir = os.path.dirname(os.path.normpath(os.path.abspath(__file__)))

    xmlfile = os.path.join(top_dir, "file/test.xml")

    disk_dir = os.path.abspath("/mnt/linux")

    if not os.path.isdir(disk_dir):
        disk_dir = top_dir 

    if not os.path.exists(xmlfile):
        print xmlfile

    ## 新建新的 虚拟机的xml 文件
    def __init__(self, name=None):
        if name is None:
            self.name = "test"
        else:
            self.name = name

        self.doc = etree.parse(self.xmlfile)

        self.disk = None
        self.create_disk = False

        self.macadd = self._random_mac()
        self.mem = None
        self.vcpu = None
        self.fullname = None
        self.xmlfile = None
        self.uuid = None
        self.xmlstring = None


    @property
    def _uuid(self):
        return str(uuid.uuid5(uuid.NAMESPACE_X500, self.name))

    @property
    def _fullname(self):
        #fullname = socket.gethostname()
        #fullname_ex = " ".join(socket.gethostbyname_ex(fullname))
        fullname = [self.name]
        pattern = re.compile("(\w*)\.(\w*)\.(\w*)")
        try:
            res = pattern.search(socket.gethostname()).groups()
            domain = ".".join(res[1:]).split('.')
            fullname.extend(domain)
        except AttributeError:
            fullname.extend(["flftuu", "com"])
        return str(".".join(fullname))

    def _random_mac(self, vmtype='qemu'):

        if vmtype == 'qemu':
            oui = [0x52, 0x54, 0x00]
        else:
            # Xen
            oui = [0x00, 0x16, 0x3E]

        mac = oui + [
            random.randint(0x00, 0xff),
            random.randint(0x00, 0xff),
            random.randint(0x00, 0xff)]
        return ':'.join(["%02x" % x for x in mac])

    @property
    def _diskdir(self):
        _disk_dir = os.path.join(self.disk_dir, self.fullname)
        if os.path.exists(_disk_dir):
            if not os.path.isdir(_disk_dir):
                try:
                    os.remove(_disk_dir)
                except OSError:
                    os.system('sudo rm -fr '+ _disk_dir)
        else:
            try:
                os.mkdir(_disk_dir)
            except OSError:
                os.system('sudo mkdir -p '+ _disk_dir)
                uid = os.getuid()
                gid = os.getgid()
                os.system(('sudo chown %s.%s %s') % (uid,gid,_disk_dir))
        return _disk_dir

    ## set name domain
    def set_name(self):
        _name = self.doc.xpath("//domain/name")[0]
        _name.text = self._fullname
        self.fullname = self._fullname

    ## set uuid domain
    def set_uuid(self):
        _uuid = self.doc.xpath("//domain/uuid")[0]
        _uuid.text = self._uuid
        self.uuid = self._uuid

    ## Set mem is default 1G
    def set_mem(self, size=1, unit="G"):
        if unit not in self.UNIT_LIST:
            print("Please input G M K")

        _mem = self.doc.xpath("//domain/memory")[0]
        _mem.set("unit", self.UNIT_LIST[unit])
        _mem.text = str(size)

        _curmem = self.doc.xpath("//domain/currentMemory")[0]
        _curmem.set("unit", self.UNIT_LIST[unit])
        _curmem.text = str(size)

        self.mem = size

    ## Set cpu numuber default 2 vcpu 
    def set_vcpu(self, num=2):
        _vcpu = self.doc.xpath("//domain/vcpu")[0]
        _vcpu.set("placement", "static")
        _vcpu.set("current", "1")

        if num > cpu_count():
            num = 2
            _vcpu.text = str(num)

        self.vcpu = num

    ## set default path disk
    def set_disk(self):
        self.disks = []
        _disks = self.doc.xpath("//domain/devices/disk")
        _disk = None
        for disk in _disks:
            if 'type' in disk.keys() and 'device' in disk.keys():
                if disk.get('type') == 'file' and disk.get('device') == 'disk' :
                    _disk = disk
                    break

        if _disk is not None:
            diskname = self._fullname + ".img"
            diskpath = os.path.join(self._diskdir, diskname)

            if os.path.isfile(diskpath):
                self.create_disk = True

            __disk = None
            for chil in _disk.getchildren():
                if chil.tag == "source":
                    __disk = chil
                    break

            if __disk is not None:
                __disk.set('file', diskpath)
                self.disk = diskpath
                self.disks.append(diskpath)

    ## set default path cdrom
    def set_cdrom(self):
        pass

    ## set default network
    def set_net(self):
        _intfs = self.doc.xpath("//domain/devices/interface")
        _intf = None
        for intf in _intfs:
            if 'type' in intf.keys():
                if intf.get('type') == "network":
                    _intf = intf
                    break

        __intf = None
        if _intf is not None:
            for chil in _intf.getchildren():
                if chil.tag == "mac":
                    __intf = chil
                    break

            if __intf is not None:
                __intf.set("address", str(self.macadd))

        
    ## save new vm xml file
    def save_xml(self, out_xmlfile=None):
        if out_xmlfile is None:
            _out_xmlfile = self.fullname + ".xml" 
            out_xmlfile = os.path.join(self._diskdir, _out_xmlfile)

        self.doc.write(out_xmlfile, method="xml")
        self.xmlfile = out_xmlfile
        self.xmlstring = etree.tostring(self.doc)

    @property
    def get_fullname(self):
        return self._fullname

    @property
    def get_randmac(self):
        return self.macadd

    @property
    def create_xml(self):
        self.set_uuid()
        self.set_name()
        self.set_vcpu()
        self.set_mem()
        self.set_disk()
        self.set_net()
        self.save_xml()
        self.xmlstring = etree.tostring(self.doc)


if __name__ == '__main__':
    kx = KvmXml("leidong")
    kx.create_xml
    print kx.xmlfile
    print kx.xmlstring
