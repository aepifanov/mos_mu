#!/usr/bin/python

import io
import yaml
import os
import shutil
import sys

def get_from_env(name):
    if name in os.environ:
        return os.environ[name]
    else:
        sys.exit("Please specify " + name)


def priority(value):
    try: 
        return int(value)
    except ValueError:
        return None


def run_or_die(cmd):
    if os.system(cmd)!=0:
        sys.exit(cmd + "has been failed with")


def repo_exists(repos,name):
    for repo in repos:
        if 'name' in repo:
            if repo['name']==name:
                return True
    return False


def main():
    env_id=get_from_env("ENV_ID")
    name=get_from_env("NAME")
    filename="cluster_{}/attributes.yaml".format(env_id)

    os.chdir("/tmp")
    run_or_die("fuel env --env {} --attributes --download".format(env_id))
    shutil.copyfile(filename, filename+".orig")

    with io.open(filename, "r") as ifile:
        data=yaml.load(ifile)

    if repo_exists(data['editable']['repo_setup']['repos']['value'], name):
        print "Repo with name " + name + " already exists"
        sys.exit()

    data['editable']['repo_setup']['repos']['value'].append(
            {'name':    name,
            'priority': priority(get_from_env("PRIORITY")),
            'section':  get_from_env('SECTION'),
            'suite':    get_from_env('SUITE'),
            'type':     get_from_env('TYPE'),
            'uri':      get_from_env('URL'),
        })

    with io.open(filename, "w") as ofile:
        yaml.dump(data,ofile, default_flow_style=False)

    run_or_die("fuel env --env {} --attributes --upload".format(env_id))

if __name__ == '__main__':
    main()
