#coding: utf-8

# vim: tabstop=4 shiftwidth=4 softtabstop=4

#author@: leidong


from vm import CreateVm
from xml import KvmXml

def main(name="test", uri=None):
    cv = CreateVm(name, uri)
    kx = KvmXml(name)
    kx.create_xml
    cv.new_vm(kx)

