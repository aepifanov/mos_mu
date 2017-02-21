#!/usr/bin/env python
#    Copyright 2017 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


import os
import yaml

from ansible.module_utils.basic import AnsibleModule
from fuelclient.objects import Environment
from fuelclient.client import APIClient


def remove_from_env(env_id, name):
    """Removes a repository with the given name from the env settings"""
    env_obj = Environment(env_id)
    settings = env_obj.get_settings_data()

    old_repos = settings['editable']['repo_setup']['repos']['value']
    new_repos = [x for x in old_repos if x['name'] != name]
    settings['editable']['repo_setup']['repos']['value'] = new_repos

    env_obj.set_settings_data(settings)


def remove_from_release(release, name):
    """
    Removes a repository with the given name from the release.
    Uses fuelclient's internals directly due to absence of release
    objects/methods in older Fuel versions.
    """
    client = APIClient

    data = client.get_request("releases")

    for rel_data in data:
        if rel_data['name'] == release:
            release_id = rel_data['id']
            repos = \
                rel_data['attributes_metadata']['editable'
                    ]['repo_setup']['repos']['value']

            repos = [x for x in repos if x['name'] != name]

            rel_data['attributes_metadata']['editable'
                ]['repo_setup']['repos']['value'] = repos

            client.put_request("releases/{}/".format(release_id), rel_data)
            return

    raise Exception("No such release found: {}".format(release))


def main():
    Module = AnsibleModule(
        argument_spec=dict(
            env_id=dict(required=False, type='str'),
            name=dict(required=True, type='str'),
            release=dict(required=False, type='str')
        )
    )

    env_id = Module.params['env_id']
    release = Module.params['release']
    repo_name = Module.params['name']

    try:
        if not env_id and not release:
            raise BaseException("Either env_id or release must be given")
        if env_id and repo_name:
            remove_from_env(env_id, repo_name)
        if release and repo_name:
            remove_from_release(release, repo_name)

    except Exception as e:
        Module.fail_json(msg="Exception occurred {}".format(e))

    Module.exit_json(changed=True, result=0)

if __name__ == "__main__":
    main()