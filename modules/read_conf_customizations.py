#!/bin/env python

import ConfigParser
import os

from ansible.module_utils.basic import AnsibleModule

module = None


def run_or_die(cmd):
    if os.system(cmd) != 0:
        module.fail_json(msg="Command {} failed.".format(cmd))


def config_to_dict(file, config, limit):
    cfg = []
    default_items = set(config.items('DEFAULT'))
    for section in config.sections():
        # Config prasee includes all items from DEFAULT secton
        # into items for each section. We need to exclude them
        section_content = set(config.items(section)) - default_items
        for key, value in section_content:
            c = dict()
            c['file'] = file
            c['section'] = section
            c['key'] = key
            c['value'] = value
            if limit != "":
                c['limit'] = limit
            cfg.append(c)

    # Add parameters from DEFAULT section
    for key, value in default_items:
        c = dict()
        c['file'] = file
        c['section'] = 'default'
        c['key'] = key
        c['value'] = value
        if limit != "":
            c['limit'] = limit
        cfg.append(c)

    return cfg


def main():
    module = AnsibleModule(
        argument_spec=dict(
            path=dict(required=True, type='str'),
            limit=dict(required=True, type='str'),
        ))

    params = module.params

    path = params['path']
    limit = params['limit']

    config = []
    files = []
    dirs = []

    dirs.append(path)
    if limit != "":
        p = path + '/' + limit
        dirs = filter(os.path.isdir, [os.path.join(p, d) for d in os.listdir(p)])

    cp = ConfigParser.ConfigParser()
    for d in dirs:
        for (path, _, files) in os.walk(d):
            if len(files) == 0:
                continue
            for f in files:
                f = path + '/' + f
                cp.read(f)
                if limit != "":
                    _, lim = os.path.split(d)
                else:
                    lim = ""
                config += config_to_dict(f, cp, lim)

    module.exit_json(changed=True, result=str(config))

if __name__ == '__main__':
    main()
