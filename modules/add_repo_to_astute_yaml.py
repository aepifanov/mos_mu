#!/bin/env python

import io
import yaml
import os
import shutil
import time

from ansible.module_utils.basic import AnsibleModule

module = None


def run_or_die(cmd):
    if os.system(cmd) != 0:
        module.fail_json(msg="Command {} failed.".format(cmd))


def repo_exists(repos, name):
    for repo in repos:
        if 'name' in repo:
            if repo['name'] == name:
                return True
    return False


def main():
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(required=True, type='str'),
            url=dict(required=True, type='str'),
            suite=dict(required=True, type='str'),
            section=dict(required=True, type='str'),
            type=dict(required=True, type='str'),
            priority=dict(required=True, type='int'),
        ))

    params = module.params

    name = params['name']
    url = params['url']
    suite = params['suite']
    section = params['section']
    type = params['type']
    priority = params['priority']

    if os.path.isfile("/etc/astute.yaml"):
        filename = "/etc/astute.yaml"
        directory = "/etc/astute_bak/"
    elif os.path.isfile("/etc/fuel/astute.yaml"):
        filename = "/etc/fuel/astute.yaml"
        directory = "/etc/fuel/astute_bak/"
    else:
        module.fail_json(msg="astute.yaml not found")

    with io.open(filename, "r") as ifile:
        data = yaml.load(ifile)

    if repo_exists(data['BOOTSTRAP']['repos'], name):
        print "Repo with name " + name + " already exists"
        module.exit_json(changed=False, result=0)

    data['BOOTSTRAP']['repos'].append(
            {'name': name,
             'priority': priority,
             'section': section,
             'suite': suite,
             'type': type,
             'uri': url})

    if not os.path.exists(directory):
        os.mkdir(directory,0755)
    timestamp = str(time.time()).replace('.','_')
    shutil.copyfile(filename, directory+"astute.yaml_"+timestamp)

    with io.open(filename, "w") as ofile:
        yaml.dump(data, ofile, default_flow_style=False)

    module.exit_json(changed=True, result=0)

if __name__ == '__main__':
    main()
