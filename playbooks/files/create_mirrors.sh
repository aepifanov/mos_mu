#!/bin/bash

REPOS=${1:-$REPOS}
REPOS=${REPOS:?"REPOS is undefined!"}
OS=${2:-$OS}
OS=${OS:?"OS is undefined!"}

LOCAL_MIRROR_PATH="/var/www/nailgun"

cd "${LOCAL_MIRROR_PATH}" || exit 1

RET=0
URLS=$(echo $REPOS | sed s/u\'/\'/g | sed s/\'/\"/g | jq  .[].url | sed s/\"//g)

LINK_DEST="--link-dest=${OS}"
for REPO in $URLS; do
    NAME=${REPO##*/}
    RSYNC_URL=${REPO/http:\/\/mirror.fuel-infra.org/rsync:\/\/mirror.fuel-infra.org\/mirror}
    rsync -vvrczIP --chmod=Dugo+x "${LINK_DEST}" "${RSYNC_URL}/" "${NAME}" || exit 1
    LINK_DEST="--link-dest=../${NAME}/"
done

exit ${RET}

