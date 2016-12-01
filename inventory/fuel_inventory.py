#!/bin/env python

from fuelclient.client import APIClient
import json
import re
from subprocess import Popen, PIPE


def get_inventory_json():
    def add_fuel_to_inventory(inventory, fuel_client):
        ip_regex = r'^[a-z]+://(?P<server_address>[^:]+)[:/]'
        re_match = re.search(ip_regex, fuel_client.root)
        fuel_ip = re_match.groupdict()['server_address']
        cmd = ['hostname']
        cmd_exec = Popen(cmd, stdout=PIPE, stderr=PIPE)
        fuel_hostname, err = cmd_exec.communicate()
        fuel_hostname = fuel_hostname.strip()
        inventory['fuel'] = {'hosts': [fuel_hostname]}
        inventory['_meta']['hostvars'][fuel_hostname] = {}
        fuel_meta = inventory['_meta']['hostvars'][fuel_hostname]
        fuel_meta['ansible_host'] = 'localhost'
        fuel_meta['ansible_connection'] = 'local'
        cmd = "fuel --fuel-version 2>&1 | awk -F ':' '/^release/ {print $2}'"
        cmd_exec = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True)
        fuel_release, err = cmd_exec.communicate()
        if not cmd_exec.returncode:
            fuel_meta['mos_release'] = fuel_release.strip(' :\n\'"')

    fc = APIClient
    nodes_list = fc.get_request('nodes')
    clusters_list = fc.get_request('clusters')
    cluster_release = {}
    for cluster in clusters_list:
        cluster_release[cluster['id']] = cluster['fuel_version']
    inventory = {}
    if '_meta' not in inventory:
        inventory['_meta'] = {}
        inventory['_meta']['hostvars'] = {}
    for node in nodes_list:
        if node['status'] != "ready":
            continue
        if node['online'] != True:
            continue
        inventory['_meta']['hostvars'][node['fqdn']] = {}
        host_meta = inventory['_meta']['hostvars'][node['fqdn']]
        host_meta['ansible_host'] = node['ip']
        if node['cluster']:
            host_meta['mos_release'] = cluster_release[node['cluster']]
            cluster = 'env_%d' % node['cluster']
            if cluster not in inventory:
                inventory[cluster] = {}
                inventory[cluster]['hosts'] = []
            inventory[cluster]['hosts'].append(node['fqdn'])
        else:
            host_meta['mos_release'] = None
        host_meta.update(node)
        for role in node['roles']:
            if role not in inventory:
                inventory[role] = {}
                inventory[role]['hosts'] = []
            inventory[role]['hosts'].append(node['fqdn'])
    add_fuel_to_inventory(inventory, fc)
    return json.dumps(inventory, indent=2)


if __name__ == '__main__':
    print(get_inventory_json())
