#!/bin/env python
from ansible.module_utils.basic import *
from xml.etree import ElementTree
from subprocess import PIPE, Popen


def main():
    pcs_error_message = ""
    module = AnsibleModule(argument_spec={})
    process = Popen(['pcs', 'status', 'xml'], stdout=PIPE)
    cib = (process.communicate()[0])
    root = ElementTree.fromstring(cib)

    for node in root.iterfind('./nodes/node'):
        pcs_node_name = node.get('name')
        pcs_node_online = node.get('online')
        pcs_node_standby = node.get('standby')
        pcs_node_maintenance = node.get('maintenance')

        if pcs_node_maintenance == "true":
            pcs_error_message += "Pacemaker: Node %s in maintenance mode. " % pcs_node_name

        if pcs_node_online == "false":
            pcs_error_message += 'Pacemaker: Node %s in offline state. ' % pcs_node_name

        if pcs_node_standby == "true":
            pcs_error_message += 'Pacemaker: Node %s in standby mode. ' % pcs_node_name

    for resource in root.iterfind('./resources//resource'):
        pcs_resource_node_name = "some nodes"
        pcs_resource_name = resource.get('id')
        pcs_resource_role = resource.get('role') # Started
        pcs_resource_active = resource.get('active') # true
        pcs_resource_managed = resource.get('managed') # true
        pcs_resource_failed = resource.get('failed') # false
        pcs_resource_nodes_running_on = resource.get('nodes_running_on') # > 0
        for pcs_resource_node in resource.iterfind('node'):
            pcs_resource_node_name = pcs_resource_node.get('name')

        if pcs_resource_role not in ["Started", "Master", "Slave"]:
            pcs_error_message += "Pacemaker: Resource %s is in %s state on %s. " % (pcs_resource_name,  pcs_resource_role, pcs_resource_node_name)
        elif pcs_resource_active == "false":
            pcs_error_message += "Pacemaker: Resource %s is not active on %s. " % (pcs_resource_name, pcs_resource_node_name)
        elif pcs_resource_nodes_running_on == 0:
            pcs_error_message += "Pacemaker: Resource %s is not running on any node. " % pcs_resource_name

        if pcs_resource_managed == "false":
            pcs_error_message += "Pacemaker: Resource %s is unmanaged on %s. " % (pcs_resource_name, pcs_resource_node_name)

        if pcs_resource_failed == "true":
            pcs_error_message += "Pacemaker: Resource %s is in failed state on %s. " % (pcs_resource_name, pcs_resource_node_name)

    if not pcs_error_message:
        module.exit_json(changed=False, meta='ok')
    else:
        module.fail_json(msg=pcs_error_message)

if __name__ == '__main__':
    main()
