#!/bin/bash -x

ENVS=${1:-$ENV_ID}
ENVS=${ENVS:-"all"}

echo "Upgrade envs"


if [[ "${ENVS}" == "all" ]]; then
    ENVS="$(fuel2 env list -c id -f value)"
fi

for envid in ${ENVS}; do
    cd /tmp
    fuel env --env ${envid} --attributes --download
    # Change kernel and headers, remove unused dkms packages
    sed -i -e 's/generic-lts-trusty/generic-lts-xenial/g' \
    -e '/^\([[:blank:]]*\)hpsa-dkms$/d' cluster_${envid}/attributes.yaml
    fuel env --env ${envid} --attributes --upload
    # Remove old IBP
    rm -vf /var/www/nailgun/targetimages/env_${envid}_*
done

systemctl restart nailgun #Is astute should be restarted?


