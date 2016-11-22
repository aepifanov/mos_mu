#!/bin/bash -x

echo "Upgrade bootstrap"

cd /etc/fuel-bootstrap-cli
cp fuel_bootstrap_cli.yaml fuel_bootstrap_cli.yaml.bak
sed -i -e 's/generic-lts-trusty/generic-lts-xenial/g' \
       -e '/-[[:blank:]]*hpsa-dkms$/d' fuel_bootstrap_cli.yaml
fuel-bootstrap build --activate --label bootstrap-kernel44
if fuel-bootstrap list | grep bootstrap-kernel44 | grep -q active; then
    echo "Bootstrap image successfully built and activated"
else
    echo "Failed to build bootstrap with 4.4 kernel"
    exit 1
fi


echo "Upgrade misc"


sed -i '/osd_mount_options_xfs/s/delaylog,//g' /etc/puppet/modules/osnailyfacter/manifests/globals/globals.pp

for f in /usr/share/fuel-openstack-metadata/openstack.yaml \
         /usr/lib/python2.7/site-packages/fuel_agent/drivers/nailgun.py \
         /usr/lib/python2.7/site-packages/nailgun/fixtures/openstack.yaml; do
    sed -i -e 's/generic-lts-trusty/generic-lts-xenial/g' \
        -e '/^\([[:blank:]]*\)\("*\)hpsa-dkms/d' ${f}
done


echo "Upgrade release"


update_releases=$(mktemp)
cat << EOF > ${update_releases}
update releases set "attributes_metadata" =
    replace("attributes_metadata", 'lts-trusty', 'lts-xenial')
    where name like '%Ubuntu%14.04%';
update releases set "attributes_metadata" =
    replace("attributes_metadata", 'hpsa-dkms\n', '')
    where name like '%Ubuntu%14.04%';
EOF
cat ${update_releases} | su postgres -c 'psql nailgun'
rm ${update_releases}

echo "Done"

