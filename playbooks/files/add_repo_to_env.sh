#!/bin/bash -x

ENV_ID=${1:-$ENV_ID}
ENV_ID=${ENV_ID:?"Please specify env_id"}
NAME=${2:-$NAME}
NAME=${NAME:?"Please specify Name"}
TYPE=${3:-$TYPE}
TYPE=${TYPE:?"Please specify Type"}
URL=${4:-$URL}
URL=${URL:?"Please specify URL"}
SUITE=${5:-$SUITE}
SUITE=${SUITE:?"Please specify Suite"}
SECTION=${6:-$SECTION}
SECTION=${SECTION:?"Please specify Section"}
PRIORITY=${7:-$PRIORITY}
PRIORITY=${PRIORITY:?"Please specify Priority"}


cd /tmp
fuel env --env ${ENV_ID} --attributes --download
cp cluster_${ENV_ID}/attributes.yaml cluster_${ENV_ID}/attributes_orig.yaml
fgrep "${NAME}" cluster_${ENV_ID}/attributes_orig.yaml && exit 0
REPO="      - name: ${NAME}
        priority: ${PRIORITY}
        section: ${SECTION}
        suite: ${SUITE}
        type: ${TYPE}
        uri: ${URL}"
awk -v repo="${REPO}" '/type: custom_repo_configuration/ {
    print;
    getline;
    print;
    print repo;
    next;}1' cluster_${ENV_ID}/attributes_orig.yaml > cluster_${ENV_ID}/attributes.yaml
fuel env --env ${ENV_ID} --attributes --upload



