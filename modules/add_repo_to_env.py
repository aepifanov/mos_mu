#!/bin/env python

import io
import yaml
import os
import shutil

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
            env_id=dict(required=True, type='str'),
            name=dict(required=True, type='str'),
            url=dict(required=True, type='str'),
            suite=dict(required=True, type='str'),
            section=dict(required=True, type='str'),
            type=dict(required=True, type='str'),
            priority=dict(required=True, type='int'),
        ))

    params = module.params

    env_id = params['env_id']
    name = params['name']
    url = params['url']
    suite = params['suite']
    section = params['section']
    type = params['type']
    priority = params['priority']

    filename = "cluster_{}/attributes.yaml".format(env_id)

    os.chdir("/tmp")

    run_or_die("fuel env --env {} --attributes --download".format(env_id))
    shutil.copyfile(filename, filename+".orig")

    with io.open(filename, "r") as ifile:
        data = yaml.load(ifile)

    if repo_exists(data['editable']['repo_setup']['repos']['value'], name):
        print "Repo with name " + name + " already exists"
        module.exit_json(changed=False, result=0)

    data['editable']['repo_setup']['repos']['value'].append(
            {'name': name,
             'priority': priority,
             'section': section,
             'suite': suite,
             'type': type,
             'uri': url})

    with io.open(filename, "w") as ofile:
        yaml.dump(data, ofile, default_flow_style=False)

    run_or_die("fuel env --env {} --attributes --upload".format(env_id))

    module.exit_json(changed=True, result=0)

if __name__ == '__main__':
    main()
