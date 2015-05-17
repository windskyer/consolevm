#coding: utf-8

# vim: tabstop=4 shiftwidth=4 softtabstop=4

#author@: leidong


from vm import CreateVm
from xml import KvmXml
from common import cfg

CONF = cfg.CONF

def main():
    cv = CreateVm(CONF.name, CONF.uri, CONF.ostype)
    kx = KvmXml(CONF.name)
    kx.create_xml
    cv.new_vm(kx)

