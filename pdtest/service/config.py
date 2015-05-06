#!/usr/bin/env python
import argparse

from ConfigParser import ConfigParser
from ConfigParser import re


import sys

def find_config_files():
    pass

class PdtestException(Exception):
    '''youself Pdtest  Exception class'''

    message = str("An unknown exception occurred.")

    def __init__(self, message=None, **kwargs):
        Exception.__init__(self)
        self.kwargs = kwargs
        if not message:
            try:
                message = self.message % kwargs
            except Exception:
                exc_info = sys.exc_info()
                raise exc_info[0], exc_info[1], exc_info[2]
            message = self.message

        self.msg = message
        super(PdtestException, self).__init__(message)

    def __str__(self):
        return (self.msg)

    def __unicode__(self):
        return unicode(self.msg)

class ConfigException(PdtestException):
    """ Config file not found """
    message = str("Config file not found")

class Config(object):

      ## init function
    def __init__(self, nobject="Pdtest"):

        self.__sections = []
        self.__options = {}
        self.__servers = []

        self._object = nobject
        self._get_config()


    def _get_config(self):
        self._default_config_files =  find_config_files(self._object)
        self._args = self._setup_args_ssh(self._object)

        if not self._default_config_files:
            self._default_config_files = self._args.config_file
        if not self._default_config_files:
            raise PdtestException("Not Found configure file" )

        self._file = self._default_config_files
        self._cf = ConfigParser()
        self._cf.read(self._file)
        self._default_config_files = " | ".join(self._file)

