#!/usr/bin/python

import io
import yaml
import sys

def priority(value):
    try: 
        return int(value)
    except ValueError:
        return None

with io.open(sys.argv[1], "r") as ifile:
    data=yaml.load(ifile)

    data['editable']['repo_setup']['repos']['value'].append(
            {'name':    sys.argv[2],
            'priority': priority(sys.argv[3]),
            'section':  sys.argv[4],
            'suite':    sys.argv[5],
            'type':     sys.argv[6],
            'uri':      sys.argv[7],
        })
    with io.open(sys.argv[1], "w") as ofile:
        yaml.dump(data,ofile, default_flow_style=False)
