import utils
import argparse

@utils.arg(
    '--volume_type',
    help=argparse.SUPPRESS)
@utils.arg(
    '--availability-zone',
    metavar='<availability-zone>',
    default=None,
    help='Availability zone for volume (Optional, Default=None)')
@utils.arg(
    '--availability_zone',
    help=argparse.SUPPRESS)
@utils.arg('--metadata',
           type=str,
           nargs='*',
           metavar='<key=value>',
           help='Metadata key=value pairs (Optional, Default=None)',
           default=None)
@utils.service_type('volume')
def do_create(cs, args):
    """Add a new volume."""

    volume_metadata = None
    if args.metadata is not None:
        volume_metadata = args
    print volume_metadata


subparser = argparse.ArgumentParser()
subcommands = {}
callback = do_create
command = 'create'

print dir(callback)
arguments = getattr(callback, 'arguments', [])
print arguments

subcommands[command] = subparser
for (args, kwargs) in arguments:
    print args
    print kwargs
    subparser.add_argument(*args, **kwargs)
    subparser.set_defaults(func=callback)


