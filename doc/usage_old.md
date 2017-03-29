
Usage for MOS 6.1/7.0/8.0
=========================

Preparations
------------

First of all we would recommend to gather current customizations:
```
ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<env_id>}'
```
More details you can find here:
[gather_customizations.yml](doc/architecture.md#gather_customizationsyml)

During performing all steps you can use the flags for step management:

[Apply MU steps](playbooks/vars/steps/apply_mu.yml)

For example you can **skip health check step, repeat generation of APT files
or gathering customizations one more time**.
```
ansible-playbook playbooks/gather_customizations.yml -e '{"env_id":<env_id>,"gather_customizations":true}'
```
Sometimes playbooks can stop with failing and recommend to use
some flags for the solving the situation, for example, when patch
were applied not on all nodes.

Then check that all customizations are applied on new versions:
```
ansible-playbook playbooks/verify_patches.yml -e '{"env_id":<env_id>}'
```
More details you can find here:
[verify_patches.yml](doc/architecture.md#verify_patchesyml)

After that please go to the nodes **/root/mos_mu/verification/** and make sure
that all patches are applied correctly.

It is also strongly recommended to identify and copy original patches to
**patches** folder on Fuel and disable **use_current_customization** flag and
manage patches to successfully execute previous **verify_patches.yml** step.

Apply MU
--------

Update Fuel node (skip for MOS6.0):
```
ansible-playbook playbooks/update_fuel.yml
```
More details you can find here:
[update_fuel.yml](doc/architecture.md#update_fuelyml)

And apply MU:
```
ansiblee-playbook playbooks/apply_mu.yml -e '{"env_id":<env_id>}'
```
More details you can find here:
[apply_mu.yml](doc/architecture.md#apply_muyml)

This playbook contains gathering and verifying steps and you can start from
Fuel updateing step, but in this case it will apply the current customizations
and patches from **patches** folder from Fuel on each node and you will
get exactly the same customizations that were before.

Full restart
------------

For the applying updates for some services like CEPH, RabbitMQ and etc we would
recommend to restart them manually and at the same time monitor thier status.

Which services were updated you can find in output in section
**Show upgradable packages**

Please also read the upgrade section in documentation for these services.

Rollback
--------

Rollback (actually pseudo rollback) playbook can return your cluster on any
specified release and apply gathered customizations:
```
ansible-playbook playbooks/rollback.yml -e '{"env_id":<env_id>,"rollback":"<release_name>"}'
```
More details you can find here:
[rollback.yml](doc/architecture.md#rollbackyml)

Local repos mirrors
-------------------

If nodes don't have access to http://mirror.fuel-infra.org/ you can create and sync
local mirrors:
```
ansible-playbook playbooks/create_mirrors.yml -e '{"env_id":<env_id>}'
```

Then for the using them you to add **fuel_url** external variable:
```
ansible-playbook playbooks/apply_mu.yml -e '{"env_id":<env_id>,"fuel_url":"http://<FUEL_IP>:8080"}'
```

