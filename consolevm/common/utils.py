#coding: utf-8
#author leidong

import os 


def arg(*args, **kwargs):
    """Decorator for CLI args."""
    def _decorator(func):
        add_arg(func, *args, **kwargs)
        return func
    return _decorator

def add_arg(f, *args, **kwargs):
    """Bind CLI arguments to a shell.py `do_foo` function."""
    if not hasattr(f, 'arguments'):
        f.arguments = []

    # NOTE(sirp): avoid dups that can occur when the module is shared across
    # tests.
    if (args, kwargs) not in f.arguments:
        # Because of the semantics of decorator composition if we just append
        # to the options list positional options will appear to be backwards.
        f.arguments.insert(0, (args, kwargs))

def env(*vars, **kwargs):
    """ 
    returns the first environment variable set
    if none are non-empty, defaults to '' or keyword arg default
    """
    for v in vars:
        value = os.environ.get(v, None)
        if value:
            return value
    return kwargs.get('default', '')

def service_type(stype):
    """
    Adds 'service_type' attribute to decorated function.
    Usage:
        @service_type('volume')
        def mymethod(f):
            ...
    """
    def inner(f):
        f.service_type = stype
        return f
    return inner

