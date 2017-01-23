#!/bin/bash -x

if [[ $(uname -r) =~ ^4.4 ]]; then
    echo “Running new kernel, no action needed”
    exit
fi

apt-get -q update
apt-get install -q -y \
linux-image-generic-lts-xenial \
linux-headers-generic-lts-xenial

KVERS=$(apt-cache depends linux-image-generic-lts-xenial | awk '/linux-image-([0-9].*)/ {print $2}')
KVERS=${KVERS/linux-image-/}
for pkg in $(dpkg-query --showformat '${binary:Package}\n' -W '*-dkms' | egrep -v 'i40e|contrail' ); do
    conf=$(dpkg -L ${pkg} | grep dkms.conf$)
    vers=$(awk -F'=' '/^PACKAGE_VERSION=/ {print $2}' ${conf} | tr -d '"')
    MODS=$(awk -F'=' '/^BUILT_MODULE_NAME/ {print $2}' ${conf})
    for mod in $MODS; do
        dkms remove ${mod:?}/${vers} -k ${KVERS:?}/x86_64 || :
    done
    apt-get purge -y ${pkg}
done

if [[ -f /etc/ceph/ceph.conf ]]; then
    sed -i 's|^osd_mount_options_xfs = .*|osd_mount_options_xfs = rw,relatime,inode64,logbsize=256k,allocsize=4M|g' /etc/ceph/ceph.conf
fi
