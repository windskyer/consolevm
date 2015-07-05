"""
Command-line interface to the consolevm API.
"""
from vm import CreateVm
from xml import KvmXml
from xml import GetXml

class actions_module(object):
    
    @staticmethod
    def vm_create(cv, args):
        for name in args.name:
            cv(name)
            kx = KvmXml(name)
            kx.create_xml
            cv.new_vm(kx,args.qemu.savedir)

    @staticmethod
    def vm_delete(cv, args):
        for name in args.name:
            cv(name)
            gx = GetXml(cv.get_xmlstring)
            cv.get_disk_dir(gx)
            cv.delete

    @staticmethod
    def vm_stop(cv, args):
        for name in args.name:
            cv(name)
            cv.stop

    @staticmethod
    def vm_reboot(cv, args):
        for name in args.name:
            cv(name)
            cv.reboot

    @staticmethod
    def vm_start(cv, args):
        for name in args.name:
            cv(name)
            cv.start(args.qemu.savedir)

    @staticmethod
    def vm_status(cv, args):
        for name in args.name:
            cv(name)
            if cv.is_active:
                print "%s is running " %  cv._fullname
            else:
                print "%s is shut off " %  cv._fullname

    @staticmethod
    def vm_save(cv, args):
        for name in args.name:
            cv(name)
            cv.save(args.qemu.savedir)

    @staticmethod
    def vm_getmac(cv, args):
        for name in args.name:
            cv(name)
            gx = GetXml(cv.get_xmlstring)
            print "%s vm mac address %s"  % (cv._fullname, str(gx.get_macaddr))

    @staticmethod
    def vm_list(cv, args):
        for k,v in cv.list_vm.items():
            if v:
                print "%s vm is running" % k
            else:
                if args.alls:
                    print "%s vm is shut off" % k

    @staticmethod
    def vm_getdisk(cv, args):
        for name in args.name:
            cv(name)
            gx = GetXml(cv.get_xmlstring)
            print "%s vm mac address %s"  % (cv._fullname, str(gx.get_disk(gx)))
