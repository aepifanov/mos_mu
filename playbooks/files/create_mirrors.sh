#!/bin/bash

REPOS=${1:-$REPOS}
REPOS=${REPOS:?"REPOS is undefined!"}

LOCAL_MIRROR_PATH="/var/www/nailgun"

RET=0
URLS=$(echo $REPOS | sed s/u\'/\'/g | sed s/\'/\"/g | jq  .[].url | sed s/\"//g)
LINK_DEST=""
for REPO in $URLS; do
    NAME=${REPO##*/}
    LINK_DEST+="--link-dest=${LOCAL_MIRROR_PATH}/${NAME} "
done

for REPO in $URLS; do
    NAME=${REPO##*/}
    RSYNC_URL=${REPO/http:\/\/mirror.fuel-infra.org/rsync:\/\/mirror.fuel-infra.org\/mirror}
    rsync -vazrcPt --chmod=Dugo+x "${LINK_DEST}" "${RSYNC_URL}/" "${LOCAL_MIRROR_PATH}/${NAME}"
done

exit ${RET}

