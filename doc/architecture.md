Inventory
=========

Inventory Python script generate inverntory data for Ansible using Fuel API.
For review inventory you can run this script separatly.

Folder structure
================

By default it looks like this (might be configured in conf file):

Fuel
----

Variables in config:
```
fuel_dir:         "/root/fuel_mos_mu"
fuel_custom_dir:  "{{ fuel_dir }}/customizations"
fuel_patches_dir: "{{ fuel_dir }}/patches"
```

Direrctory tree:
```
/root/fuel_mos_mu
├── customizations
│   └── node-3
│       └── python-neutron_customization.patch
└── patches
    └── 01-python-nova.patch
```

* Folder **customizations** is used for gathering customizations from nodes.
  Customizations are placed in folder with nodename.
  This folder will be cleared taks **gather_customizations.yml** will be run
  with flag **clean_customizations: true**.
  Please be carefull with this flag since you can loose your customizations.

* Folder **patches** is used for storing set of patches which will be synced
  on nodes and used for verifying applying and applying on cloud.
  Patches should have **.patch** extentions. Please be aware that patches
  will be applied in alphabetic order, also keep in mind that if flag
  **use_current_customizations: true** is enabled current customizations
  will be also copied to **patches** folder on nodes with to
  **00-customizations** folder.
  So it is recommended to name patches with prefixes like this
  **01-\<patchname\>.patch, 02-\<patchname2\>.patch**.

Nodes
---

Variables in config:
```
mos_dir:          "/root/mos_mu"
custom_dir:       "{{ mos_dir }}/customizations"
patches_dir:      "{{ mos_dir }}/patches"
verification_dir: "{{ mos_dir }}/verification"
apt_dir:          "{{ mos_dir }}/apt"
apt_conf:         "{{ apt_dir }}/apt.conf"
apt_src_dir:      "{{ apt_dir }}/sources.list.d"
```

Direrctory tree:
```
/root/mos_mu/
├── apt
│   ├── apt.conf
│   └── sources.list.d
│       ├── fuel.list
│       ├── GA.list
│       ├── latest.list
│       ├── mu-1.list
│       ├── mu-2.list
│       ├── mu-3.list
│       └── mu-4.list
├── customizations
│   └── python-neutron
│       ├── 1%3a2015.1.1-1~u14.04+mos5341
│       │   └── usr
|       |         ............
│       └── python-neutron_customization.patch
├── patches
│   ├── 00-customizations
│   │   └── python-neutron_customization.patch
│   └── 01-python-nova.patch
└── verification
    ├── python-neutron
    │   ├── 1%3a2015.1.1-1~u14.04+mos5371
    │   │   ├── python-neutron_1%3a2015.1.1-1~u14.04+mos5371_all.deb
    │   │   └── usr
    |   |   |     ............
    │   └── python-neutron_customization.patch
    └── python-nova
        ├── 1%3a2015.1.1-1~u14.04+mos19695
        │   ├── python-nova_1%3a2015.1.1-1~u14.04+mos19695_all.deb
        │   └── usr
        |         ............
        └── 01-python-nova.patch
```

* Folder **apt** contains apt.conf which is always used for apt and uses
  only **sources.lists.d** folder for sources lists.

* **apt/sources.list.d** contains sources lists for all configured in config
  repositories.

* **customizations** folder consist from folders for custmoized packages.
  Packages folder contains folder (current package version) with unpacked
  package and diff file between this unpacked version and current installed
  (customized) version.

* **patches** folder contains all patches from Fuel **patches** folder and
  current customizations **00-customizations** if flag
  **use_current_customizations: true** is enabled. This folder is cleared every
  time when task **verify_patches.yml** is started.

* **verification** folder consist from folders for custmoized packages.
  Packages folder contains folder (canditate package version, by default,
  configured by flag **pkg_ver_for_verifiacation: "Candidate"**) with unpacked
  package and patches files witch should be applied.


Tasks
=====

apt_update.yml
--------------

* Clean **apt** folder on nodes.
* Generate and copy on nodes sources.list files from
  [templates/sources.list.j2](../playbooks/templates/sources.list.j2) using i
  configuring repositories in conf file.
* Generate and copy on nodes **apt.conf** file from
  [templates/apt_conf.j2](../playbooks/templates/apt_conf.j2).
* Perform APT update using generated **apt.conf** on nodes.

get_current_mu.yml
------------------

* Run [files/get_current_mu.sh](../playbooks/files/get_current_mu.sh) script to
  identify which MU currently is applied. Actually this scipt just uses one by
  one sources.list from sources.list.d folder and check if any package have
  available 'update'.  If noone have update it means that exactly this MU is
  installed now. It can return 'undefine' result, that means the node has
  installed packages from different MU(or other undefined) repos.

verify_md5.yml
--------------

* Run [files/verify_packages_ubuntu.sh](../playbooks/files/verify_packages_ubuntu.sh)
  script to identify which packages have available new version and customized.
  For all these packages script calculate MD5 sum and compared with origin.
* Return list of customized packages in **md5_verify_result** variable.

clean_customizations.yml
------------------------

* Delete **customizations** folder on Fuel.
* Delete **customizations** folder on nodes.

gather_current_customizations.yml
---------------------------------

* Check if customizations is already gathered ( **customization** folder exits
  on nodes ).
* Create **customizations** folder if doesn't exist.
* If doesn't exist for each customized package in **md5_verify_result** run s
  [files/get_package_customizations.sh](../playbooks/files/get_package_customizations.sh).
  This script unpacks cached origin installed package (or download if cached is
  not exists) and make a diff between origin and current state.
* If customizations were gatherd, download them on Fuel in
  **customizations/\<nodename\>**.

verify_patches.yml
------------------

* Clean **patches** folder on nodes.
* Clean **verification** folder on nodes.
* Copy patches from Fuel folder **patches** to nodes folder **patches**
  (if **rollback** is not enabled).
* Run [files/use_customizations.sh](../playbooks/files/use_customizations.sh)
  script which copy current patches from **customizations** folder to
  **patches** folder (if **use_curret_customization** is enabled).
* Run [files/verify_patches.sh](../playbooks/files/verify_patches.sh) script
  which:
    * Make usre that each patch affect only one package.
    * Download and extract candidate package if it is not already exists.
    * Try to apply patch. If more than 1 patch affects this package they will
      be applied by alphabetic order.

apt_upgrade.yml
---------------

* Correct dependencies.
* Perform APT upgrade.

apply_patches.yml
-----------------

* Run [files/apply_patches.sh]files/apply_patches.sh() script which just
  applies sorted by relaive name patches in **patches** folder on nodes.

rollback_upgrade.yml
--------------------

* Correct dependencies.
* Perform APT upgrade using only specified in variable **rollback** MU name.

Playbooks
=========

By default all playbooks are defined for all nodes except Fuel.
It might be run for any node and group of nodes using standart flag **--limit**
like this `--limit=cluster_2:compute` (all comuters in cluster_2).

All playbooks include variable file
[vars/mos_releases/{{ mos_release }}.yml](../playbooks/vars/mos_releases)
based on **mos_release** variable, which dynamicaly defined during
the inventarization phase.

Also it is possible to pass extra variables via cli using standard flar **-e**,
like this `-e '{"apt_update":false, "verify_md5":true}'`.

gather_customizations.yml
-------------------------

Makes sure that customizations were not gatherd  already and then gathers them.
If you need to gather it again you can use flag **clean_customizations**.

Runs the set of tasks based on set of flags which allow or deny executing some
tasks. Uses
[vars/steps/gather_customizations.yml](../playbooks/vars/steps/gather_customizations.yml)
set of flags.

Run the following tasks:
* [tasks/apt_update.yml](../playbooks/tasks/apt_update.yml)
* [tasks/get_current_mu.yml](../playbooks/tasks/get_current_mu.yml)
* [tasks/verify_md5.yml](../playbooks/tasks/verify_md5.yml)
* [tasks/clean_customizations.yml](../playbooks/tasks/clean_customizations.yml)
* [tasks/gather_customizations.yml](../playbooks/tasks/clean_customizations.yml)

verify_patches.yml
------------------

Just verify applying patches on target version of packages
**pkg_ver_for_verifiacation**.

Uses [vars/steps/verify_patches.yml](../playbooks/vars/steps/verify_patches.yml)
set of flags.

Runs only two steps:
* [tasks/apt_update.yml](../playbooks/tasks/apt_update.yml)
* [tasks/verify_patches.yml](../playbooks/tasks/verify_patches.yml)

apply_mu.yml
------------

Apply MU and reapply current customizations(if enabled).

By default uses [var/steps/apply_mu.yml](../playbooks/var/steps/apply_mu.yml)
set of flags.

Run the following tasks:
* [tasks/apt_update.yml](../playbooks/tasks/apt_update.yml)
* [tasks/get_current_mu.yml](../playbooks/tasks/get_current_mu.yml)
* [tasks/verify_md5.yml](../playbooks/tasks/verify_md5.yml)
* [tasks/clean_customizations.yml](../playbooks/tasks/clean_customizations.yml)
* [tasks/gather_customizations.yml](../playbooks/tasks/gather_customizations.yml)
* [tasks/verify_patches.yml](../playbooks/tasks/verify_patches.yml)
* [tasks/apt_upgrade.yml](../playbooks/tasks/apt_upgrade.yml)
* [tasks/apply_patches.yml](../playbooks/tasks/apply_patches.yml)

and then include one more playbook:
* restart_services.yml

restart_services.yml
--------------------

Restart all services for each role specified in
[vars/mos_releases/<mos_release>.yml](../playbooks/vars/mos_releases).

Might be used separatly.

rollback.yml
------------

This is pseudo rollback, since it does not save the current state, but provide
you a mechanism for install any MU release (that you have initially for
rollback) and apply gathered customizations, of course as usual with verifying
patches before installing.

Uses [vars/steps/rollback.yml](../playbooks/vars/steps/rollback.yml) set of
flags.
