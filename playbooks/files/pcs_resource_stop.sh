#!/bin/bash

RESOURCE=${1:?"ERROR: Please specify resource name."}
TIMEOUT=${2:-600}

OUT=$(pcs resource show "${RESOURCE}") || {
    echo "WARNING: Resource ${RESOURCE} is not present!";
    exit 100;}

OUT+=$(pcs resource show clone_"${RESOURCE}")

echo "${OUT}" | fgrep "target-role=Stopped" && {
    echo "WARNING: Resource ${RESOURCE} is stopped!"
    exit 1;}

pcs resource cleanup "${RESOURCE}" --wait="${TIMEOUT}"

pcs resource disable "${RESOURCE}" --wait="${TIMEOUT}" || {
    echo "ERROR: Resource ${RESOURCE} failed to stop";
    exit 2;}
