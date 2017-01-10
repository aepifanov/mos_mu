#!/bin/env python

import io
import os
import shutil
import subprocess
import yaml

from ansible.module_utils.basic import AnsibleModule

module = None


def run_or_die(cmd):
    if os.system(cmd) != 0:
        module.fail_json(msg="Command {} failed".format(cmd))


def repo_exists(repos, name):
    for repo in repos:
        if 'name' in repo:
            if repo['name'] == name:
                return True
    return False


def main():
    module = AnsibleModule(
        argument_spec=dict(
            release=dict(required=True, type='str'),
            name=dict(required=True, type='str'),
            url=dict(required=True, type='str'),
            suite=dict(required=True, type='str'),
            section=dict(required=True, type='str'),
            type=dict(required=True, type='str'),
            priority=dict(required=True, type='int'),
        ))

    params = module.params

    release = params['release']
    name = params['name']
    url = params['url']
    suite = params['suite']
    section = params['section']
    type = params['type']
    priority = params['priority']

    cmd = "fuel2 release list | awk '/" + release + "/ {print 2}'"
    p = subprocess.Popen(cmd,
                         shell=True,
                         stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    rel_id, err = p.communicate()
    rel_id = int(rel_id)

    filename = "/tmp/rel_{}_repos.yml".format(rel_id)

    run_or_die("fuel2 release repos list {} -f yaml > {}".format(rel_id,
                                                                 filename))
    shutil.copyfile(filename, filename+".orig")

    with io.open(filename, "r") as ifile:
        data = yaml.load(ifile)

    if repo_exists(data, name):
        module.exit_json(changed=False, result=0)

    data.append(
            {'name': name,
             'priority': priority,
             'section': section,
             'suite': suite,
             'type': type,
             'uri': url})

    with io.open(filename, "w") as ofile:
        yaml.dump(data, ofile, default_flow_style=False)

    run_or_die("fuel2 release repos update -f {} {}".format(filename, rel_id))

    module.exit_json(changed=True, result=0)

if __name__ == '__main__':
    main()
