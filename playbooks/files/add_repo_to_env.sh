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
$(dirname $0)/add_repo_to_env.py cluster_${ENV_ID}/attributes.yaml ${NAME} ${PRIORITY} ${SECTION} ${SUITE} ${TYPE} ${URL}
fuel env --env ${ENV_ID} --attributes --upload
